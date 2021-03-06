class Iamswer::Session
  include ActiveModel::Model
  include Iamswer::Session::Finder

  attr_accessor :id,
    :is_invalidated,
    :logged_out_at,
    :valid_until,
    :user

  alias_attribute :isInvalidated, :is_invalidated
  alias_attribute :loggedOutAt, :logged_out_at
  alias_attribute :validUntil, :valid_until
  alias_method :invalidated?, :is_invalidated

  def self.new_from_json body
    Iamswer::Error.add_context body: body

    error = body["error"]
    raise Iamswer::Error.from error if error

    session = new body.slice :id,
      :isInvalidated,
      :loggedOutAt,
      :validUntil

    # session's user can be nil if the session is no longer active
    # so we should be careful not to simply parse the user data
    if body["user"]
      session.user = Iamswer::User.typed_new_from_json body["user"]
    end

    session
  end

  def self.authenticate!(login, password)
    body = Iamswer::Client.post(
      "/api/v1/sessions/authenticate",
      login: login,
      password: password,
    )

    new_from_json body
  end

  def valid_until=(value)
    @valid_until = value.is_a?(DateTime) ? value : DateTime.parse(value)
  end

  def logged_out?
    logged_out_at.present?
  end

  def attributes(json_compatible: false)
    attributes = {
      id: id,
      is_invalidated: is_invalidated,
      logged_out_at: logged_out_at&.to_s,
      valid_until: valid_until.to_s,
      user: user,
    }

    if json_compatible
      attributes[:isInvalidated] = attributes.delete :is_invalidated
      attributes[:loggedOutAt] = attributes.delete :logged_out_at
      attributes[:validUntil] = attributes.delete :valid_until
    end

    attributes
  end
end
