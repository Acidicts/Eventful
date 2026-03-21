class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :action, :request_method, :path, presence: true
end
