class ExportDocumentService < DocumentBaseService
  EXPORTING_KEY = 'exporting_documents:'.freeze
  ERROR_PREFIX = 'documents_errors:'
  TTL = 1.minutes

  def call
    redis.llen(READY_FOR_EXPORT_LIST_KEY).times do
      document_id = redis.lpop(READY_FOR_EXPORT_LIST_KEY)
      return if document_id.nil?
      exporting_key = EXPORTING_KEY + document_id
      next if redis.exists(exporting_key) == 1

      redis.set(exporting_key, document_id, ex: TTL)
      begin
        response = gateway.send_document(body(document_id), timeout: TTL)
        next if response[:code] = 200

        log_error(document_id, response[:body])
      rescue Timeout::Error, Redis::BaseError => e
        log_error(document_id, e)
        puts "ID: #{document_id}, ERROR: " + e.to_s
      end
    end
  end

  private

  def gateway
    @gateway ||= Gateway.new
  end

  def body(document_id)
    {
      data: redis.hget('docs:' + document_id, 'data'),
      author: redis.hmget('docs:' + document_id, 'author')
    }
  end

  def log_error(document_id, error)
    redis.set(ERROR_PREFIX + document_id, error.to_s)
  end
end

