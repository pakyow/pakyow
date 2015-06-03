class Pakyow::Request
  def socket?
    env['pakyow.socket'] == true
  end
end
