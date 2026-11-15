package ph.kitabiyahe.kitabiyahe

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    private data class PendingBackup(val bytes: ByteArray, val result: MethodChannel.Result)
    private var pendingBackup: PendingBackup? = null
    private val createBackupRequest = 0x4B42

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ph.kitabiyahe.kitabiyahe/backup")
            .setMethodCallHandler { call, result ->
                if (call.method != "saveJsonBackup") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val json = call.argument<String>("json")
                val name = call.argument<String>("name")
                if (json == null || name.isNullOrBlank() || name.contains('/') || name.contains('\\')) {
                    result.error("INVALID_BACKUP", "A JSON backup and simple filename are required.", null)
                    return@setMethodCallHandler
                }
                val bytes = json.toByteArray(Charsets.UTF_8)
                if (bytes.size > 1024 * 1024) {
                    result.error("BACKUP_TOO_LARGE", "Backup exceeds the 1 MB file limit.", null)
                    return@setMethodCallHandler
                }
                if (pendingBackup != null) {
                    result.error("BACKUP_BUSY", "Finish the current save dialog first.", null)
                    return@setMethodCallHandler
                }
                pendingBackup = PendingBackup(bytes, result)
                val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "application/json"
                    putExtra(Intent.EXTRA_TITLE, name)
                }
                try {
                    @Suppress("DEPRECATION")
                    startActivityForResult(intent, createBackupRequest)
                } catch (_: ActivityNotFoundException) {
                    pendingBackup = null
                    result.error("NO_FILE_PICKER", "A system file picker is unavailable. Use Copy JSON instead.", null)
                } catch (_: SecurityException) {
                    pendingBackup = null
                    result.error("FILE_PICKER_RESTRICTED", "This device restricted file saving. Use Copy JSON instead.", null)
                }
            }
    }

    @Deprecated("Used for the FlutterActivity file-picker result on supported Android versions.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != createBackupRequest) return
        val pending = pendingBackup ?: return
        pendingBackup = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending.result.success(false)
            return
        }
        Thread {
            try {
                val stream = contentResolver.openOutputStream(uri, "wt")
                    ?: throw IOException("No writable stream")
                stream.use { it.write(pending.bytes) }
                runOnUiThread { pending.result.success(true) }
            } catch (_: Exception) {
                runOnUiThread {
                    pending.result.error("SAVE_FAILED", "Could not save the backup. Choose another folder or use Copy JSON.", null)
                }
            }
        }.start()
    }
}
