json.extract! task, :id, :name, :description, :completed, :notes, :upload, :created_at, :updated_at
json.url task_url(task, format: :json)
