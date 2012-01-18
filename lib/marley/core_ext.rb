class Object
  def send_or_default(meth, default)
    respond_to?(meth) ? send(meth) : default
  end
  def send_or_nil(meth)
    send_or_default(meth,nil)
  end
end
