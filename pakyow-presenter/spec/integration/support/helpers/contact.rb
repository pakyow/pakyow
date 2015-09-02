class Contact
  attr_accessor :full_name, :email

  def initialize(full_name, email)
    @full_name = full_name
    @email = email
  end
end
