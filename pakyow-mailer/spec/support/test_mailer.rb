class TestMailer < Pakyow::Mailer
  def delivered_to
    @delivered_to
  end

  def deliver(recipient)
    @delivered_to ||= []
    @delivered_to << recipient
  end
end
