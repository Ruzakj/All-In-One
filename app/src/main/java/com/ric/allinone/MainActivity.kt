package com.ric.allinone

import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.ric.emuhub.StoragePermissionActivity
import com.ruzakj.ricbrowser.MainActivity as BrowserActivity
import com.ruzakj.speedometer.MainActivityV2
import id.ric.isotocso.MainActivity as CsoActivity

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.rgb(7, 10, 18)
        setContentView(buildDashboard())
    }

    private fun buildDashboard(): ScrollView {
        val scroll = ScrollView(this).apply { setBackgroundColor(Color.rgb(7, 10, 18)) }
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(28), dp(20), dp(28))
        }
        column.addView(label("RIC ALL-IN-ONE", 28f, Color.WHITE, true))
        column.addView(label("Lima aplikasi, satu tempat.", 14f, Color.rgb(148, 163, 184), false).apply {
            setPadding(0, dp(6), 0, dp(22))
        })
        column.addView(card("ISO / CSO Tools", "Kompres ISO, buat CSO, CHD, dan kelola cutscene") { open(CsoActivity::class.java) })
        column.addView(card("Emu Hub", "Library dan runtime emulator dalam satu aplikasi") { open(StoragePermissionActivity::class.java) })
        column.addView(card("Speedometer", "GPS, lean angle, telemetry, history, dan replay") { open(MainActivityV2::class.java) })
        column.addView(card("Ric Browser", "Browser ringan, multi-tab, extensions, adblock, dan media tools") { open(BrowserActivity::class.java) })
        column.addView(card("Ric Space / VibeTube", "Musik dan seluruh toolbox PWA versi lokal") { open(VibeTubeActivity::class.java) })
        scroll.addView(column)
        return scroll
    }

    private fun card(title: String, subtitle: String, click: () -> Unit): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            isClickable = true
            isFocusable = true
            setPadding(dp(18), dp(18), dp(18), dp(18))
            background = GradientDrawable().apply {
                cornerRadius = dp(18).toFloat()
                setColor(Color.rgb(17, 24, 39))
                setStroke(dp(1), Color.rgb(35, 211, 238))
            }
            addView(label(title, 19f, Color.WHITE, true))
            addView(label(subtitle, 13f, Color.rgb(148, 163, 184), false).apply { setPadding(0, dp(7), 0, 0) })
            setOnClickListener { click() }
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = dp(14)
            }
            elevation = dp(3).toFloat()
        }
    }

    private fun label(value: String, size: Float, color: Int, bold: Boolean) = TextView(this).apply {
        text = value
        textSize = size
        setTextColor(color)
        gravity = Gravity.START
        if (bold) setTypeface(typeface, android.graphics.Typeface.BOLD)
    }

    private fun open(type: Class<*>) = startActivity(Intent(this, type))
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
}
