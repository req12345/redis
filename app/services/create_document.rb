class CreateDocument < DocumentBaseService
  CREATE_PREFIX = 'docs:'.freeze
  DOCS_ID_COUNTER_KEY = 'docs:ids'.freeze

  def create(data, author = nil)
    id = redis.incr(DOCS_ID_COUNTER_KEY)
    if author.present?
      redis.hset(create_key(id), :data, data, author: author)
    else
      redis.hset(create_key(id), :data, data)
    end

    prepare_for_export(id)
    id
  end

  private

  def create_key(id)
    CREATE_PREFIX + id.to_s
  end

  def prepare_for_export(document_id)
    redis.rpush(READY_FOR_EXPORT_LIST_KEY, document_id)
  end
end