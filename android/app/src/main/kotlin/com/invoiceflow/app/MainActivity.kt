package com.invoiceflow.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val NOTIFICATION_CHANNEL = "invoiceflow/notifications"
    private val WHATSAPP_CHANNEL = "com.invoiceflow.app/whatsapp"
    private val NOTIFICATION_ID = 1
    private val CHANNEL_ID = "payment_reminders"

    private var pendingPdfPath: String? = null
    private var pendingWhatsappPackage: String? = null
    private var pendingPhoneNumber: String? = null
    private var shouldShowPdfOnResume = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Notification channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "Payment Reminder"
                    val body = call.argument<String>("body") ?: "You have pending payments"
                    showNotification(title, body)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // WhatsApp channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WHATSAPP_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendWhatsAppMessage" -> {
                    val phoneNumber = call.argument<String>("phoneNumber") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    val filePath = call.argument<String>("filePath") ?: ""

                    try {
                        sendWhatsAppMessageWithFile(phoneNumber, message, filePath)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WHATSAPP_ERROR", e.message, null)
                    }
                }
                "sendWhatsAppMessageOnly" -> {
                    val phoneNumber = call.argument<String>("phoneNumber") ?: ""
                    val message = call.argument<String>("message") ?: ""

                    try {
                        sendWhatsAppMessageOnly(phoneNumber, message)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WHATSAPP_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun sendWhatsAppMessageOnly(phoneNumber: String, message: String) {
        // Open WhatsApp chat with pre-filled message (no file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encode(message)}")
            setPackage("com.whatsapp")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        // Check if WhatsApp is installed
        if (intent.resolveActivity(packageManager) != null) {
            startActivity(intent)
        } else {
            // Try WhatsApp Business
            intent.setPackage("com.whatsapp.w4b")
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
            } else {
                throw Exception("WhatsApp not installed")
            }
        }
    }

    override fun onResume() {
        super.onResume()

        // If we should show PDF dialog when user returns
        if (shouldShowPdfOnResume && pendingPdfPath != null && pendingWhatsappPackage != null && pendingPhoneNumber != null) {
            shouldShowPdfOnResume = false

            // Small delay to ensure smooth transition
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                try {
                    val file = File(pendingPdfPath!!)
                    if (file.exists()) {
                        val fileUri: Uri = FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.fileprovider",
                            file
                        )

                        val pdfIntent = Intent(Intent.ACTION_SEND).apply {
                            type = "application/pdf"
                            putExtra(Intent.EXTRA_STREAM, fileUri)
                            putExtra("jid", "$pendingPhoneNumber@s.whatsapp.net")
                            setPackage(pendingWhatsappPackage)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }

                        startActivity(pdfIntent)
                    }
                } catch (e: Exception) {
                    android.util.Log.e("WhatsApp", "Failed to send PDF on resume: ${e.message}")
                } finally {
                    // Clear pending data
                    pendingPdfPath = null
                    pendingWhatsappPackage = null
                    pendingPhoneNumber = null
                }
            }, 500) // Short delay for smooth UX
        }
    }

    private fun sendWhatsAppMessageWithFile(phoneNumber: String, message: String, filePath: String) {
        val file = File(filePath)

        if (!file.exists()) {
            throw Exception("File not found: $filePath")
        }

        // Open WhatsApp chat with message pre-filled
        val messageIntent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encode(message)}")
            setPackage("com.whatsapp")
        }

        var whatsappPackage = "com.whatsapp"
        if (messageIntent.resolveActivity(packageManager) == null) {
            // Try WhatsApp Business
            messageIntent.setPackage("com.whatsapp.w4b")
            whatsappPackage = "com.whatsapp.w4b"
            if (messageIntent.resolveActivity(packageManager) == null) {
                throw Exception("WhatsApp not installed")
            }
        }

        // Store PDF info for when user returns to app
        pendingPdfPath = filePath
        pendingWhatsappPackage = whatsappPackage
        pendingPhoneNumber = phoneNumber
        shouldShowPdfOnResume = true

        // Open WhatsApp with message
        startActivity(messageIntent)
    }

    private fun showNotification(title: String, body: String) {
        createNotificationChannel()
        
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)

        with(NotificationManagerCompat.from(this)) {
            notify(NOTIFICATION_ID, builder.build())
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Payment Reminders"
            val descriptionText = "Notifications for pending payment follow-ups"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}