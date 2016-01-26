module Admin
  class JuniorReportsController < ApplicationController
    authorize_resource

    def show
      send_data JuniorReport.rows.join("\n"),
                filename: 'JuniorReport.csv',
                type: 'text/csv',
                disposition: 'inline'
    end

    private
  end
end
