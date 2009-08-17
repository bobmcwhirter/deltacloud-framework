
module DeltaCloud

  class AuthException < Exception
  end

  class BaseDriver

    def flavor(credentials, opts)
      flavors = flavors(credentials, opts)
      return flavors.first unless flavors.empty?
      nil
    end

    def flavors(credentials, ops)
      []
    end

    def flavors_by_architecture(credentials, architecture)
      flavors(credentials, :architecture => architecture)
    end

    def realm(credentials, opts)
      realms = realms(credentials, opts)
      return realms.first unless realms.empty?
      nil
    end

    def realms(credentials, opts=nil)
      []
    end

    def image(credentials, opts)
      images = images(credentials, opts)
      return images.first unless images.empty?
      nil
    end

    def images(credentials, ops)
      []
    end

    def instance(credentials, opts)
      instances = instances(credentials, opts)
      return instances.first unless instances.empty?
      nil
    end

    def instances(credentials, ops)
      []
    end

    def create_instance(credentials, image_id, opts)
    end
    def start_instance(credentials, id)
    end
    def stop_instance(credentials, id)
    end
    def reboot_instance(credentials, id)
    end

    def storage_volume(credentials, opts)
      volumes = storage_volumes(credentials, opts)
      return volumes.first unless volumes.empty?
      nil
    end

    def storage_volumes(credentials, ops)
      []
    end

    def storage_snapshot(credentials, opts)
      snapshots = storage_snapshots(credentials, opts)
      return snapshots.first unless snapshots.empty?
      nil
    end

    def storage_snapshots(credentials, ops)
      []
    end

    def filter_on(collection, attribute, opts)
      return collection if opts.nil?
      return collection if opts[attribute].nil?
      filter = opts[attribute]
      if ( filter.is_a?( Array ) )
        return collection.select{|e| filter.include?( e.send(attribute) ) }
      else
        return collection.select{|e| filter == e.send(attribute) }
      end
    end
  end

end
