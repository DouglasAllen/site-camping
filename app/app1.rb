require 'camping'

Camping.goes :Watch

module Watch::Models
  
end

module Watch::Controllers
  class Index
    def get      
      render :index
    end
  end
end

module Watch::Views
  def index
    Time.now.to_s
  end
end

