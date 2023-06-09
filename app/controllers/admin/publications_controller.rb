module Admin
  class PublicationsController < ApplicationController
    authorize_resource

    def create
      @rating_list = RatingList.find(params[:rating_list_id])
      message = @rating_list.publish
      if message
        render "shared/alert", locals: { message: message }
      else
        @publications = @rating_list.publications
        render "admin/rating_lists/publications", formats: :js
      end
    end

    def show
      @publication = Publication.find(params[:id])
    end

    def edit
      @publication = Publication.find(params[:id])
      @rating_list = @publication.rating_list
    end

    def update
      @publication = Publication.find(params[:id])
      @publication.update(pub_params)
    end
    
    private

    def pub_params
      params.require(:publication).permit(:notes)
    end
  end
end
