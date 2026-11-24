.pragma library

var bg = "#06080B"
var bgLift = "#0A0D12"
var surface = "#0E1218"
var surface2 = "#121821"
var surface3 = "#182029"
var stroke = "#1D2632"
var strokeSoft = "#151C25"
var text = "#EEF2F8"
var textDim = "#98A3B4"
var textFaint = "#5B6678"

var mint = "#5CE9BA"
var mintDim = "#2E8E73"
var red = "#FF6B7D"
var redDim = "#8E3744"
var blue = "#82A9FF"
var amber = "#F4C97D"
var violet = "#B492FF"

var fontFamily = "Adwaita Sans"
var fontMono = "Adwaita Mono"

var expenseCategories = ["Casa", "Cibo", "Trasporti", "Svago", "Salute", "Shopping", "Bollette", "Altro"]
var incomeCategories = ["Stipendio", "Freelance", "Investimenti", "Regalo", "Rimborso", "Altro"]

var categoryColors = {
    "Casa": "#82A9FF",
    "Cibo": "#F4C97D",
    "Trasporti": "#5CE9BA",
    "Svago": "#B492FF",
    "Salute": "#FF8FA3",
    "Shopping": "#FFB27A",
    "Bollette": "#6FD3E8",
    "Altro": "#8D99AB",
    "Stipendio": "#5CE9BA",
    "Freelance": "#82A9FF",
    "Investimenti": "#B492FF",
    "Regalo": "#F4C97D",
    "Rimborso": "#6FD3E8"
}

function categoryColor(name) {
    return categoryColors[name] || "#8D99AB"
}

function withAlpha(hex, a) {
    var h = hex.replace("#", "")
    if (h.length === 3)
        h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2]
    var r = parseInt(h.substring(0, 2), 16) / 255
    var g = parseInt(h.substring(2, 4), 16) / 255
    var b = parseInt(h.substring(4, 6), 16) / 255
    return Qt.rgba(r, g, b, a)
}

function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

function groupThousands(intPart) {
    var out = ""
    var n = intPart.length
    for (var i = 0; i < n; ++i) {
        if (i > 0 && (n - i) % 3 === 0)
            out += "."
        out += intPart[i]
    }
    return out
}

function money(value, symbol, decimals, signed) {
    if (symbol === undefined) symbol = "€"
    if (decimals === undefined) decimals = 2
    var v = Number(value)
    if (!isFinite(v)) v = 0
    var neg = v < -0.0000001
    var abs = Math.abs(v)
    var fixed = abs.toFixed(decimals)
    var parts = fixed.split(".")
    var out = groupThousands(parts[0])
    if (decimals > 0)
        out += "," + parts[1]
    var sign = neg ? "−" : (signed ? "+" : "")
    return sign + out + " " + symbol
}

function moneyShort(value, symbol) {
    var v = Number(value)
    var abs = Math.abs(v)
    var sign = v < 0 ? "−" : ""
    if (abs >= 1000)
        return sign + (abs / 1000).toFixed(abs >= 10000 ? 0 : 1).replace(".", ",") + "k " + symbol
    return sign + Math.round(abs) + " " + symbol
}

function monthName(m, short) {
    var full = ["Gennaio", "Febbraio", "Marzo", "Aprile", "Maggio", "Giugno",
                "Luglio", "Agosto", "Settembre", "Ottobre", "Novembre", "Dicembre"]
    var abbr = ["GEN", "FEB", "MAR", "APR", "MAG", "GIU", "LUG", "AGO", "SET", "OTT", "NOV", "DIC"]
    return short ? abbr[Math.max(0, Math.min(11, m - 1))] : full[Math.max(0, Math.min(11, m - 1))]
}

function weekdayShort(i) {
    return ["LUN", "MAR", "MER", "GIO", "VEN", "SAB", "DOM"][i]
}

function dayLabel(iso) {
    var d = new Date(iso + "T12:00:00")
    var wd = ["Domenica", "Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato"][d.getDay()]
    return wd + " " + d.getDate() + " " + monthName(d.getMonth() + 1, false).toLowerCase()
}

function greeting() {
    var h = new Date().getHours()
    if (h < 5) return "Buonanotte"
    if (h < 12) return "Buongiorno"
    if (h < 18) return "Buon pomeriggio"
    return "Buonasera"
}

function pad2(n) { return n < 10 ? "0" + n : "" + n }
