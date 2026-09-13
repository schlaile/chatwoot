class AdministratorNotifications::ChannelNotificationsMailer < AdministratorNotifications::BaseMailer
  def facebook_disconnect(inbox)
    subject = I18n.t('mailers.subjects.channel_notifications.facebook_disconnect')
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def instagram_disconnect(inbox)
    subject = I18n.t('mailers.subjects.channel_notifications.instagram_disconnect')
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def tiktok_disconnect(inbox)
    subject = I18n.t('mailers.subjects.channel_notifications.tiktok_disconnect')
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def whatsapp_disconnect(inbox)
    subject = I18n.t('mailers.subjects.channel_notifications.whatsapp_disconnect')
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def email_disconnect(inbox)
    subject = I18n.t('mailers.subjects.channel_notifications.email_disconnect')
    send_notification(subject, action_url: inbox_url(inbox))
  end
end
