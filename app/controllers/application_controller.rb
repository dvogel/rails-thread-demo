class ApplicationController < ActionController::API
  def sleep
    t1 = Time.now.to_i
    seconds = params[:seconds].to_i
    Kernel.sleep(seconds)
    t2 = Time.now.to_i
    render plain: (t2 - t1).to_s
  end
end
