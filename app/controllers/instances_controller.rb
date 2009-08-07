class InstancesController < ApplicationController

  include DriverHelper
  include ConversionHelper

  around_filter :catch_auth

  def index
    build_filter( :id )
    @instances = driver.instances( credentials, @filter )

    respond_to do |format|
      format.html
      format.json
      format.xml {
        render :xml=>convert_to_xml( :instance, @instances )
      }
    end
  end

  def show
    @instance = driver.instance( credentials, :id=>params[:id] )

    respond_to do |format|
      format.html {
        render :text=>'resource not found', :status=>404 and return unless @instance
      }
      format.json
      format.xml {
        render :nothing=>true, :status=>404 and return unless @instance
        render :xml=>convert_to_xml( :instance, @instance )
      }
    end
  end

  def new
    @instance = Instance.new( {
                  :id=>params[:id],
                  :image_id=>params[:image_id],
                } )
    @image   = driver.image( credentials, :id => params[:image_id] )
    @flavors = driver.flavors( credentials, { :architecture=>@image.architecture } )
  end

  def create
    @image   = driver.image( credentials, :id=>params[:image_id] )
    puts @image.inspect
    respond_to do |format|
      format.html {
        if ( params[:flavor_id].nil? )
          @flavors = driver.flavors_by_architecture( credentials, @image.architecture )
          @instance = Instance.new( {
                        :id=>params[:id],
                        :image_id=>params[:image_id],
                      } )
          render :action=>:new and return
        end
        instance = driver.create_instance( credentials, @image.id, params[:flavor_id] )
        redirect_to instance_url( instance.id )
      }
      format.xml {
        instance = driver.create_instance( credentials, @image.id, params[:flavor_id] )
        puts "RESULT #{instance.inspect}"
        render :xml=>convert_to_xml( :instance, instance), :status=>:created, :location=>instance_url( instance.id )
      }
    end
  end

  ##

  def start
    driver.start_instance(credentials, params[:id])
    redirect_to :action=>:show
  end

  def stop
    driver.stop_instance(credentials, params[:id])
    redirect_to :action=>:show
  end

  def destroy
    driver.delete_instance( credentials, params[:id] )
    redirect_to :action=>:show
  end

  def reboot
    driver.reboot_instance( credentials, params[:id] )
    redirect_to :action=>:show
  end

end
