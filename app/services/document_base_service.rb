class DocumentBaseService
  attr_reader :redis

  READY_FOR_EXPORT_LIST_KEY = 'ready_for_export:'.freeze

  def redis
    @redis ||= Redis.current
  end
end