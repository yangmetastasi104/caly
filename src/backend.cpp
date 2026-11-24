#include "backend.h"

#include <QDir>
#include <QFile>
#include <QHash>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRandomGenerator>
#include <QSaveFile>
#include <QStandardPaths>
#include <QDateTime>
#include <QUuid>
#include <algorithm>
#include <cmath>

namespace {
QString iso(const QDate &d) { return d.toString(Qt::ISODate); }

double round2(double v) { return std::round(v * 100.0) / 100.0; }

QString makeId() { return QUuid::createUuid().toString(QUuid::WithoutBraces); }

const QStringList kExpenseCategories = {
    QStringLiteral("Casa"),      QStringLiteral("Cibo"),
    QStringLiteral("Trasporti"), QStringLiteral("Svago"),
    QStringLiteral("Salute"),    QStringLiteral("Shopping"),
    QStringLiteral("Bollette"),  QStringLiteral("Altro"),
};

const QStringList kIncomeCategories = {
    QStringLiteral("Stipendio"), QStringLiteral("Freelance"),
    QStringLiteral("Investimenti"), QStringLiteral("Regalo"),
    QStringLiteral("Rimborso"), QStringLiteral("Altro"),
};
} // namespace

Backend::Backend(QObject *parent)
    : QObject(parent)
{
    QString dir = qEnvironmentVariable("CALY_DATA_DIR");
    if (dir.isEmpty())
        dir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
              + QStringLiteral("/caly");
    QDir().mkpath(dir);
    m_path = dir + QStringLiteral("/caly.json");
    load();
}

void Backend::load()
{
    QFile f(m_path);
    if (!f.open(QIODevice::ReadOnly)) {
        save();
        return;
    }
    const auto doc = QJsonDocument::fromJson(f.readAll());
    if (!doc.isObject())
        return;

    const QJsonObject root = doc.object();
    const QJsonObject profile = root.value(QStringLiteral("profile")).toObject();
    m_name = profile.value(QStringLiteral("name")).toString();
    m_currency = profile.value(QStringLiteral("currency")).toString(QStringLiteral("€"));
    m_monthlyTarget = profile.value(QStringLiteral("monthlyTarget")).toDouble();
    m_savingsGoal = profile.value(QStringLiteral("savingsGoal")).toDouble();
    m_onboarded = profile.value(QStringLiteral("onboarded")).toBool(false);

    m_tx.clear();
    const QJsonArray arr = root.value(QStringLiteral("transactions")).toArray();
    m_tx.reserve(arr.size());
    for (const auto &v : arr) {
        const QJsonObject o = v.toObject();
        Tx t;
        t.id = o.value(QStringLiteral("id")).toString();
        t.date = QDate::fromString(o.value(QStringLiteral("date")).toString(), Qt::ISODate);
        t.amount = round2(o.value(QStringLiteral("amount")).toDouble());
        t.type = o.value(QStringLiteral("type")).toString(QStringLiteral("expense"));
        t.category = o.value(QStringLiteral("category")).toString(QStringLiteral("Altro"));
        t.note = o.value(QStringLiteral("note")).toString();
        if (!t.date.isValid() || t.amount <= 0.0 || t.id.isEmpty())
            continue;
        if (t.type != QStringLiteral("income") && t.type != QStringLiteral("expense"))
            t.type = QStringLiteral("expense");
        m_tx.push_back(t);
    }
}

void Backend::save()
{
    QJsonObject profile;
    profile.insert(QStringLiteral("name"), m_name);
    profile.insert(QStringLiteral("currency"), m_currency);
    profile.insert(QStringLiteral("monthlyTarget"), round2(m_monthlyTarget));
    profile.insert(QStringLiteral("savingsGoal"), round2(m_savingsGoal));
    profile.insert(QStringLiteral("onboarded"), m_onboarded);

    QJsonArray arr;
    for (const auto &t : m_tx) {
        QJsonObject o;
        o.insert(QStringLiteral("id"), t.id);
        o.insert(QStringLiteral("date"), iso(t.date));
        o.insert(QStringLiteral("amount"), round2(t.amount));
        o.insert(QStringLiteral("type"), t.type);
        o.insert(QStringLiteral("category"), t.category);
        o.insert(QStringLiteral("note"), t.note);
        arr.append(o);
    }

    QJsonObject root;
    root.insert(QStringLiteral("version"), 1);
    root.insert(QStringLiteral("profile"), profile);
    root.insert(QStringLiteral("transactions"), arr);

    QSaveFile f(m_path);
    if (!f.open(QIODevice::WriteOnly))
        return;
    f.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    f.commit();
}

void Backend::bump()
{
    ++m_revision;
    save();
    emit dataChanged();
}

QString Backend::newId() const { return makeId(); }

QVector<Backend::Tx> Backend::sorted() const
{
    QVector<Tx> out = m_tx;
    std::sort(out.begin(), out.end(), [](const Tx &a, const Tx &b) {
        if (a.date != b.date)
            return a.date > b.date;
        return a.id > b.id;
    });
    return out;
}

QVariantMap Backend::txToMap(const Tx &t) const
{
    QVariantMap m;
    m.insert(QStringLiteral("id"), t.id);
    m.insert(QStringLiteral("date"), iso(t.date));
    m.insert(QStringLiteral("amount"), t.amount);
    m.insert(QStringLiteral("type"), t.type);
    m.insert(QStringLiteral("category"), t.category);
    m.insert(QStringLiteral("note"), t.note);
    return m;
}

QVariantList Backend::monthDays(int year, int month)
{
    if (month < 1 || month > 12) {
        const QDate now = QDate::currentDate();
        year = now.year();
        month = now.month();
    }

    const QDate first(year, month, 1);
    const int daysInMonth = first.daysInMonth();
    const int lead = first.dayOfWeek() - 1; // Monday-first grid
    const int cells = int(std::ceil((lead + daysInMonth) / 7.0)) * 7;

    struct Sum {
        double income = 0;
        double expense = 0;
        int count = 0;
    };
    QHash<int, Sum> sums;
    for (const auto &t : m_tx) {
        if (t.date.year() != year || t.date.month() != month)
            continue;
        Sum &s = sums[t.date.day()];
        if (t.type == QStringLiteral("income"))
            s.income += t.amount;
        else
            s.expense += t.amount;
        ++s.count;
    }

    QVariantList out;
    out.reserve(cells);
    for (int i = 0; i < cells; ++i) {
        QVariantMap cell;
        const int day = i - lead + 1;
        if (day >= 1 && day <= daysInMonth) {
            const QDate d(year, month, day);
            const Sum s = sums.value(day);
            cell.insert(QStringLiteral("inMonth"), true);
            cell.insert(QStringLiteral("day"), day);
            cell.insert(QStringLiteral("iso"), iso(d));
            cell.insert(QStringLiteral("income"), round2(s.income));
            cell.insert(QStringLiteral("expense"), round2(s.expense));
            cell.insert(QStringLiteral("net"), round2(s.income - s.expense));
            cell.insert(QStringLiteral("count"), s.count);
        } else {
            cell.insert(QStringLiteral("inMonth"), false);
            cell.insert(QStringLiteral("day"), 0);
            cell.insert(QStringLiteral("iso"), QString());
            cell.insert(QStringLiteral("income"), 0.0);
            cell.insert(QStringLiteral("expense"), 0.0);
            cell.insert(QStringLiteral("net"), 0.0);
            cell.insert(QStringLiteral("count"), 0);
        }
        out.append(cell);
    }
    return out;
}

QVariantMap Backend::monthSummary(int year, int month)
{
    double income = 0, expense = 0;
    int count = 0;
    for (const auto &t : m_tx) {
        if (t.date.year() != year || t.date.month() != month)
            continue;
        if (t.type == QStringLiteral("income"))
            income += t.amount;
        else
            expense += t.amount;
        ++count;
    }
    income = round2(income);
    expense = round2(expense);

    QVariantMap m;
    m.insert(QStringLiteral("income"), income);
    m.insert(QStringLiteral("expense"), expense);
    m.insert(QStringLiteral("net"), round2(income - expense));
    m.insert(QStringLiteral("count"), count);
    m.insert(QStringLiteral("savingsRate"), income > 0 ? round2((income - expense) / income * 100.0) : 0.0);
    return m;
}

QVariantList Backend::transactionsForDay(const QString &isoDate)
{
    const QDate d = QDate::fromString(isoDate, Qt::ISODate);
    QVariantList out;
    if (!d.isValid())
        return out;
    const QVector<Tx> all = sorted();
    for (const auto &t : all) {
        if (t.date == d)
            out.append(txToMap(t));
    }
    return out;
}

QVariantList Backend::allTransactions()
{
    QVariantList out;
    const QVector<Tx> all = sorted();
    out.reserve(all.size());
    for (const auto &t : all)
        out.append(txToMap(t));
    return out;
}

QVariantList Backend::categoryTotals(int year, int month)
{
    QHash<QString, double> sums;
    for (const auto &t : m_tx) {
        if (t.type != QStringLiteral("expense"))
            continue;
        if (t.date.year() != year)
            continue;
        if (month > 0 && t.date.month() != month)
            continue;
        sums[t.category] += t.amount;
    }

    QVector<QPair<QString, double>> rows;
    rows.reserve(sums.size());
    for (auto it = sums.cbegin(); it != sums.cend(); ++it)
        rows.append({it.key(), round2(it.value())});
    std::sort(rows.begin(), rows.end(), [](const auto &a, const auto &b) {
        return a.second > b.second;
    });

    QVariantList out;
    for (const auto &r : rows) {
        QVariantMap m;
        m.insert(QStringLiteral("category"), r.first);
        m.insert(QStringLiteral("total"), r.second);
        out.append(m);
    }
    return out;
}

QVariantList Backend::monthlySeries(int year)
{
    QVariantList out;
    for (int m = 1; m <= 12; ++m) {
        const QVariantMap s = monthSummary(year, m);
        QVariantMap row;
        row.insert(QStringLiteral("month"), m);
        row.insert(QStringLiteral("income"), s.value(QStringLiteral("income")));
        row.insert(QStringLiteral("expense"), s.value(QStringLiteral("expense")));
        row.insert(QStringLiteral("net"), s.value(QStringLiteral("net")));
        out.append(row);
    }
    return out;
}

QVariantMap Backend::yearSummary(int year)
{
    double income = 0, expense = 0;
    int count = 0;
    for (const auto &t : m_tx) {
        if (t.date.year() != year)
            continue;
        if (t.type == QStringLiteral("income"))
            income += t.amount;
        else
            expense += t.amount;
        ++count;
    }
    income = round2(income);
    expense = round2(expense);

    QVariantMap m;
    m.insert(QStringLiteral("income"), income);
    m.insert(QStringLiteral("expense"), expense);
    m.insert(QStringLiteral("net"), round2(income - expense));
    m.insert(QStringLiteral("count"), count);
    m.insert(QStringLiteral("savingsRate"), income > 0 ? round2((income - expense) / income * 100.0) : 0.0);
    return m;
}

QVariantMap Backend::lifetimeSummary()
{
    double income = 0, expense = 0;
    for (const auto &t : m_tx) {
        if (t.type == QStringLiteral("income"))
            income += t.amount;
        else
            expense += t.amount;
    }
    income = round2(income);
    expense = round2(expense);

    QVariantMap m;
    m.insert(QStringLiteral("income"), income);
    m.insert(QStringLiteral("expense"), expense);
    m.insert(QStringLiteral("net"), round2(income - expense));
    m.insert(QStringLiteral("count"), int(m_tx.size()));
    return m;
}

bool Backend::addTransaction(const QString &isoDate, double amount,
                             const QString &type, const QString &category,
                             const QString &note)
{
    const QDate d = QDate::fromString(isoDate, Qt::ISODate);
    amount = round2(amount);
    if (!d.isValid() || amount <= 0.0 || amount > 1.0e12)
        return false;
    if (type != QStringLiteral("income") && type != QStringLiteral("expense"))
        return false;

    Tx t;
    t.id = newId();
    t.date = d;
    t.amount = amount;
    t.type = type;
    t.category = category.isEmpty() ? QStringLiteral("Altro") : category.left(40);
    t.note = note.left(200);
    m_tx.push_back(t);
    bump();
    return true;
}

bool Backend::removeTransaction(const QString &id)
{
    const auto it = std::find_if(m_tx.begin(), m_tx.end(),
                                 [&id](const Tx &t) { return t.id == id; });
    if (it == m_tx.end())
        return false;
    m_tx.erase(it);
    bump();
    return true;
}

void Backend::completeOnboarding(const QString &name, const QString &currency,
                                 double monthlyTarget, double savingsGoal,
                                 bool seed)
{
    m_name = name.trimmed().isEmpty() ? QStringLiteral("Amico") : name.trimmed().left(40);
    m_currency = currency.isEmpty() ? QStringLiteral("€") : currency.left(4);
    m_monthlyTarget = std::max(0.0, round2(monthlyTarget));
    m_savingsGoal = std::max(0.0, round2(savingsGoal));
    m_onboarded = true;
    if (seed && m_tx.isEmpty())
        seedSamples();
    save();
    emit profileChanged();
    bump();
}

void Backend::updateProfile(const QString &name, const QString &currency,
                            double monthlyTarget, double savingsGoal)
{
    m_name = name.trimmed().isEmpty() ? m_name : name.trimmed().left(40);
    m_currency = currency.isEmpty() ? m_currency : currency.left(4);
    m_monthlyTarget = std::max(0.0, round2(monthlyTarget));
    m_savingsGoal = std::max(0.0, round2(savingsGoal));
    save();
    emit profileChanged();
}

void Backend::resetAll()
{
    m_tx.clear();
    m_onboarded = false;
    m_monthlyTarget = 0.0;
    m_savingsGoal = 0.0;
    save();
    emit profileChanged();
    bump();
}

QString Backend::exportJson()
{
    QString dir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    if (dir.isEmpty())
        dir = QDir::homePath();
    QDir().mkpath(dir);
    const QString path = dir + QStringLiteral("/caly-export-")
                         + QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd-HHmmss"))
                         + QStringLiteral(".json");
    QFile f(path);
    if (!f.open(QIODevice::WriteOnly))
        return QString();
    QJsonArray arr;
    for (const auto &t : sorted())
        arr.append(QJsonObject::fromVariantMap(txToMap(t)));
    QJsonObject root;
    root.insert(QStringLiteral("profile"), QJsonObject{
        {QStringLiteral("name"), m_name},
        {QStringLiteral("currency"), m_currency},
        {QStringLiteral("monthlyTarget"), m_monthlyTarget},
        {QStringLiteral("savingsGoal"), m_savingsGoal},
    });
    root.insert(QStringLiteral("transactions"), arr);
    f.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    f.close();
    return path;
}

void Backend::seedSamples()
{
    struct Seed {
        int monthsAgo;
        int day;
        double amount;
        const char *type;
        const char *category;
        const char *note;
    };

    const Seed seeds[] = {
        {2, 1, 1850.00, "income", "Stipendio", "Stipendio mensile"},
        {2, 3, 42.30, "expense", "Cibo", "Spesa settimanale"},
        {2, 6, 68.00, "expense", "Bollette", "Luce e gas"},
        {2, 9, 320.00, "income", "Freelance", "Progetto landing page"},
        {2, 12, 29.90, "expense", "Svago", "Abbonamenti streaming"},
        {2, 15, 54.20, "expense", "Trasporti", "Carburante"},
        {2, 18, 120.00, "expense", "Shopping", "Scarpe nuove"},
        {2, 22, 38.50, "expense", "Cibo", "Cena fuori"},
        {2, 26, 210.00, "expense", "Casa", "Manutenzione caldaia"},

        {1, 1, 1850.00, "income", "Stipendio", "Stipendio mensile"},
        {1, 2, 90.00, "expense", "Casa", "Arredo bagno"},
        {1, 4, 47.80, "expense", "Cibo", "Spesa settimanale"},
        {1, 7, 65.00, "expense", "Bollette", "Internet"},
        {1, 10, 280.00, "income", "Investimenti", "Dividendi ETF"},
        {1, 13, 24.00, "expense", "Salute", "Farmacia"},
        {1, 16, 58.90, "expense", "Cibo", "Spesa settimanale"},
        {1, 19, 145.00, "expense", "Shopping", "Giacca invernale"},
        {1, 21, 32.00, "expense", "Trasporti", "Abbonamento bus"},
        {1, 24, 420.00, "income", "Freelance", "Consulenza UX"},
        {1, 27, 75.00, "expense", "Svago", "Concerto"},

        {0, 1, 1850.00, "income", "Stipendio", "Stipendio mensile"},
        {0, 2, 45.60, "expense", "Cibo", "Spesa settimanale"},
        {0, 3, 12.00, "expense", "Trasporti", "Metro"},
        {0, 5, 89.90, "expense", "Bollette", "Luce e gas"},
        {0, 7, 250.00, "income", "Freelance", "Logo e brand kit"},
        {0, 9, 36.40, "expense", "Cibo", "Cena con amici"},
        {0, 11, 18.00, "expense", "Svago", "Cinema"},
        {0, 13, 110.00, "expense", "Salute", "Visita specialistica"},
        {0, 15, 62.30, "expense", "Cibo", "Spesa settimanale"},
        {0, 17, 27.50, "expense", "Shopping", "Libri"},
        {0, 19, 95.00, "expense", "Casa", "Tende nuove"},
        {0, 21, 30.00, "expense", "Trasporti", "Carburante"},
        {0, 23, 55.32, "expense", "Svago", "Weekend fuori"},
        {0, 24, 414.90, "income", "Investimenti", "Vendita posizione"},
        {0, 26, 48.70, "expense", "Cibo", "Spesa settimanale"},
    };

    const QDate today = QDate::currentDate();
    for (const Seed &s : seeds) {
        const QDate base = today.addMonths(-s.monthsAgo);
        QDate d(base.year(), base.month(), std::min(s.day, base.daysInMonth()));
        if (s.monthsAgo == 0 && d > today)
            continue;
        Tx t;
        t.id = newId();
        t.date = d;
        t.amount = s.amount;
        t.type = QString::fromUtf8(s.type);
        t.category = QString::fromUtf8(s.category);
        t.note = QString::fromUtf8(s.note);
        m_tx.push_back(t);
    }
}
