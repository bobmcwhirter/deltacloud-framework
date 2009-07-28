
module Drivers

  class AuthException < Exception
  end

  class EC2

    def safely(&block) 
      begin
        block.call
      rescue RightAws::AwsError => e
        if ( e.include?( /SignatureDoesNotMatch/ ) )
          raise AuthException.new
        elsif ( e.include?( /InvalidClientTokenId/ ) )
          raise AuthException.new
        else
          e.errors.each do |error|
            puts "ERROR #{error.inspect}"
          end
        end
      end
    end

    def images(credentials, *ids)
      ec2 = new_client( credentials )
      images = []
      safely do
        ec2.describe_images(*ids).each do |ec2_image|
          if ( ec2_image[:aws_id] =~ /^ami-/ ) 
            images << convert_image( ec2_image )
          end
        end
      end
      images
    end

    def image(credentials, id)
      ec2 = new_client(credentials)
      safely do
        ec2_images = ec2.describe_images(id)
        return nil if ec2_images.empty?
        convert_image( ec2_images.first )
      end
    end

    def instances(credentials, *ids)
      ec2 = new_client(credentials)
      instances = []
      safely do
        ec2.describe_instances(ids).each do |ec2_instance|
          instances << convert_instance( ec2_instance )
        end
      end
      instances
    end

    def instance(credentials, id)
      ec2 = new_client(credentials)
      ec2_instances = ec2.describe_instances(id)
      return nil if ec2_instances.empty?
      convert_instance( ec2_instances.first )
    end

    def accounts(credentials, *ids)
      ec2 = new_client( credentials )
      accounts = {}
      safely do
        ec2.describe_images(*ids).each do |ec2_image|
          if ( ec2_image[:aws_id] =~ /^ami-/ )
            unless ( accounts[ec2_image[:aws_owner]] ) 
              accounts[ec2_image[:aws_owner]] = Account.new( :id=>ec2_image[:aws_owner] )
            end
          end
        end
      end
      accounts.values.sort!{|l,r| l.id <=> r.id}
    end

    def account(credentials, id)
      ec2 = new_client( credentials )
      image_ids = []
      ec2.describe_images_by_owner(id).each do |ec2_image|
        image_ids << ec2_image[:aws_id]
      end
      instance_ids = []
      {
        :id=>id,
        :image_ids=>image_ids,
        :instance_ids=>instance_ids,
      } 
    end

    def create_instance(credentials, image_id)
      ec2 = new_client( credentials )
      ec2_instances = ec2.run_instances( 
                            image_id, 
                            1,1,
                            [],
                            nil,
                            '',
                            'public',
                            'm1.small' )
      convert_instance( ec2_instances.first )
    end


    def machine_types(image_id=nil)
    end

    def reboot_instance(credentials, id)
      ec2 = new_client(credentials)
      ec2.reboot_instances( id )
    end

    def delete_instance(credentials, id)
      ec2 = new_client(credentials)
      ec2.terminate_instances( id )
    end

    private

    def new_client(credentials)
      if ( credentials[:name].nil? || credentials[:password].nil? || credentials[:name] == '' || credentials[:password] == '' ) 
        raise AuthException.new
      end
      RightAws::Ec2.new(credentials[:name], credentials[:password], :cache=>false )
    end

    def convert_image(ec2_image)
      {
        :id=>ec2_image[:aws_id], 
        :description=>ec2_image[:aws_location],
        :owner_id=>ec2_image[:aws_owner],
        :architecture=>ec2_image[:aws_architecture],
      } 
    end
   
    def convert_instance(ec2_instance)
      {
        :id=>ec2_instance[:aws_instance_id], 
        :state=>ec2_instance[:aws_state].upcase,
        :image_id=>ec2_instance[:aws_image_id],
        :owner_id=>ec2_instance[:aws_owner],
        :public_address=>( ec2_instance[:dns_name] == '' ? nil : ec2_instance[:dns_name] ),
        :private_address=>( ec2_instance[:private_dns_name] == '' ? nil : ec2_instance[:private_dns_name] ),
      } 
    end

  end

end
