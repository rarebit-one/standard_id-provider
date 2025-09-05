module Admin
  class ClientsController < BaseController
    before_action :prepare_client, only: [:show, :edit, :update, :destroy]

    def index
      @clients = DemoApplication.all
    end

    def show
    end

    def new
      @client = DemoApplication.new
    end

    def create
      @client = DemoApplication.new(client_params)

      if @client.save
        redirect_to admin_client_path(@client), notice: "Client was successfully created."
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @client.update(client_params)
        redirect_to admin_client_path(@client), notice: "Client was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      @client.destroy
      redirect_to admin_clients_path, notice: "Client was successfully deleted."
    end

    private

    def prepare_client
      @client = DemoApplication.find(params[:id])
    end

    def client_params
      params.require(:demo_application).permit(:name, :client_id, :client_secret, :redirect_uris, :scopes, :active)
    end
  end
end
