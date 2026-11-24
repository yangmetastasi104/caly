#pragma once

#include <QDate>
#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QVector>

class Backend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString userName READ userName NOTIFY profileChanged)
    Q_PROPERTY(QString currency READ currency NOTIFY profileChanged)
    Q_PROPERTY(double monthlyTarget READ monthlyTarget NOTIFY profileChanged)
    Q_PROPERTY(double savingsGoal READ savingsGoal NOTIFY profileChanged)
    Q_PROPERTY(bool onboarded READ onboarded NOTIFY profileChanged)
    Q_PROPERTY(QString todayIso READ todayIso CONSTANT)
    Q_PROPERTY(int currentYear READ currentYear CONSTANT)
    Q_PROPERTY(int currentMonth READ currentMonth CONSTANT)
    Q_PROPERTY(QString dataPath READ dataPath CONSTANT)
    Q_PROPERTY(int revision READ revision NOTIFY dataChanged)

public:
    explicit Backend(QObject *parent = nullptr);

    QString userName() const { return m_name; }
    QString currency() const { return m_currency; }
    double monthlyTarget() const { return m_monthlyTarget; }
    double savingsGoal() const { return m_savingsGoal; }
    bool onboarded() const { return m_onboarded; }
    QString todayIso() const { return QDate::currentDate().toString(Qt::ISODate); }
    int currentYear() const { return QDate::currentDate().year(); }
    int currentMonth() const { return QDate::currentDate().month(); }
    QString dataPath() const { return m_path; }
    int revision() const { return m_revision; }

    Q_INVOKABLE QVariantList monthDays(int year, int month);
    Q_INVOKABLE QVariantMap monthSummary(int year, int month);
    Q_INVOKABLE QVariantList transactionsForDay(const QString &isoDate);
    Q_INVOKABLE QVariantList allTransactions();
    Q_INVOKABLE QVariantList categoryTotals(int year, int month);
    Q_INVOKABLE QVariantList monthlySeries(int year);
    Q_INVOKABLE QVariantMap yearSummary(int year);
    Q_INVOKABLE QVariantMap lifetimeSummary();

    Q_INVOKABLE bool addTransaction(const QString &isoDate, double amount,
                                    const QString &type, const QString &category,
                                    const QString &note);
    Q_INVOKABLE bool removeTransaction(const QString &id);
    Q_INVOKABLE void completeOnboarding(const QString &name, const QString &currency,
                                        double monthlyTarget, double savingsGoal,
                                        bool seedSamples);
    Q_INVOKABLE void updateProfile(const QString &name, const QString &currency,
                                   double monthlyTarget, double savingsGoal);
    Q_INVOKABLE void resetAll();
    Q_INVOKABLE QString exportJson();

signals:
    void profileChanged();
    void dataChanged();

private:
    struct Tx {
        QString id;
        QDate date;
        double amount = 0.0;
        QString type;      // "income" | "expense"
        QString category;
        QString note;
    };

    void load();
    void save();
    void seedSamples();
    void bump();
    QVariantMap txToMap(const Tx &t) const;
    QString newId() const;
    QVector<Tx> sorted() const;

    QString m_path;
    QString m_name;
    QString m_currency = QStringLiteral("€");
    double m_monthlyTarget = 0.0;
    double m_savingsGoal = 0.0;
    bool m_onboarded = false;
    QVector<Tx> m_tx;
    int m_revision = 0;
};
