Mailboxer.setup do |config|
  config.uses_emails = false
end

def get_conversation(from, to, subject)
  # 1. Busca todos los Receipts por receiver_id basandose en el user_from y user_to del MessageLegacy
  # Agrupa todos sus Receipts por los notification_id que los dos tienen
  # (si dos usuarios tienen el mismo notification_id tuvieron una conversación)
  if from and to 
    notification_ids = Receipt.
      where("receiver_id=? OR receiver_id=?", from, to).
      count(group: :notification_id).
      select{|k,v| v > 1}.
      keys 
    # 2. De ese resultado filtramos los que coincidan con el Subject, devolvemos la Conversation
    notification_ids.each do |n|
      notification = Notification.find_by_id n 
      return notification.conversation if notification.subject == subject
    end
  else 
    nil
  end
end

def start_conversation(from, to, subject, body, created_at)
  from_u = User.find_by_id from
  to_u = User.find_by_id to
  if from_u and to_u
    from_u.send_message(to_u, body, subject, true, nil, created_at)
  else
    puts "******************* INVALID USER *********************"
  end
end

def reply_to_conversation(conversation, from, body, created_at)
  # It isn't the first, so the Conversation is already there
  user = User.find_by_id from
  r = user.reply_to_conversation(conversation, body)
  r.created_at = created_at 
  r.updated_at = created_at 
  r.message.created_at = created_at 
  r.message.updated_at = created_at 
  r.message.save
  r.save
end

def start_or_reply_conversation(message_thread, message)
   
  # nolotirov2 legacy 
  # FIX: hay algunos mensajes que no tienen un user_from (bug legacy)
  # FIXME: user_to nil?
  unless message_thread.messages_legacy.map(&:user_from).include?(nil) or message_thread.messages_legacy.map(&:user_to).include?(nil)
    if message ==  message_thread.messages_legacy.first
      start_conversation(message.user_from, message.user_to, message_thread.subject, message.body, message.created_at)
    else
      conversation = get_conversation(message.user_from, message.user_to, message_thread.subject)
      #conversation = Conversation.find_by_subject message_thread.subject
      if conversation
        reply_to_conversation(conversation, message.user_from, message.body, message.created_at)
      else
        puts "******************* INVALID USER *********************"
      end
    end
  else 
    puts "******************* INVALID USER *********************"
  end
end

def start_all_threads
  #MessageThread.where(:id => 1000000..1002000).each do |mt|
  MessageThread.all.find_each do |mt|
    mt.messages_legacy.find do |m| 
      start_or_reply_conversation(mt,m)
    end
  end
end

def start_a_thread thread_id
  mt = MessageThread.find(thread_id)
  mt.messages_legacy.find do |m| 
    start_or_reply_conversation(mt,m)
  end
end

threads = ["1008701", "1008702", "1008748", "1008801", "1008810", "1008811", "1008812", "1010864", "1015280", "1015281", "1021217"]

threads.each {|t| start_a_thread t } 
