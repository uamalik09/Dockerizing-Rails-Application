# frozen_string_literal: true

class Task < ApplicationRecord
  has_one_attached :upload

  validate :upload_content_type

  private

  def upload_content_type
    if upload.attached? && !upload.content_type.in?(%w(image/jpeg image/png application/pdf))
      errors.add(:upload, 'must be a JPEG, PNG, or PDF')
    end
  end
end
