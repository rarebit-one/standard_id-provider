module StandardId
  module Provider
    class Engine < ::Rails::Engine
      isolate_namespace StandardId::Provider
    end
  end
end
