#include "backend.h"

#include <QCommandLineParser>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QStandardPaths>
#include <QTimer>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("Caly"));
    QGuiApplication::setApplicationDisplayName(QStringLiteral("Caly"));
    QGuiApplication::setOrganizationName(QStringLiteral("Caly"));
    QGuiApplication::setApplicationVersion(QStringLiteral("1.0.0"));
    QGuiApplication::setWindowIcon(QIcon(QStringLiteral(":/qt/qml/Caly/assets/caly-logo.png")));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Caly — calendario di entrate e spese"));
    parser.addHelpOption();
    parser.addVersionOption();
    QCommandLineOption shotOpt(QStringLiteral("screenshot"),
                               QStringLiteral("Salva uno screenshot e chiudi."),
                               QStringLiteral("path"));
    QCommandLineOption demoOpt(QStringLiteral("demo"),
                               QStringLiteral("Prepara un profilo demo con movimenti di esempio."));
    QCommandLineOption resetOpt(QStringLiteral("reset"),
                                QStringLiteral("Cancella i dati locali prima di avviare."));
    QCommandLineOption delayOpt(QStringLiteral("delay"),
                                QStringLiteral("Ritardo screenshot in ms."),
                                QStringLiteral("ms"), QStringLiteral("1800"));
    QCommandLineOption stepOpt(QStringLiteral("onboarding-step"),
                               QStringLiteral("Apre l'onboarding a un passo specifico (0-3)."),
                               QStringLiteral("n"), QStringLiteral("-1"));
    QCommandLineOption pageOpt(QStringLiteral("page"),
                               QStringLiteral("Pagina iniziale (0-3)."),
                               QStringLiteral("n"), QStringLiteral("-1"));
    QCommandLineOption dialogOpt(QStringLiteral("open-dialog"),
                                 QStringLiteral("Apre il dialogo nuovo movimento."));
    QCommandLineOption dayOpt(QStringLiteral("open-day"),
                              QStringLiteral("Apre il pannello del giorno corrente."));
    QCommandLineOption selfOpt(QStringLiteral("selftest"),
                               QStringLiteral("Esegue i test del backend ed esce."));
    QCommandLineOption autoOpt(QStringLiteral("autopilot"),
                               QStringLiteral("Completa l'onboarding automaticamente."));
    QCommandLineOption autoAddOpt(QStringLiteral("auto-add"),
                                  QStringLiteral("Apre il dialogo e salva un movimento di prova."));
    QCommandLineOption autoDelOpt(QStringLiteral("auto-delete"),
                                  QStringLiteral("Apre la conferma di eliminazione."));
    parser.addOption(shotOpt);
    parser.addOption(demoOpt);
    parser.addOption(resetOpt);
    parser.addOption(delayOpt);
    parser.addOption(stepOpt);
    parser.addOption(pageOpt);
    parser.addOption(dialogOpt);
    parser.addOption(dayOpt);
    parser.addOption(selfOpt);
    parser.addOption(autoOpt);
    parser.addOption(autoAddOpt);
    parser.addOption(autoDelOpt);
    parser.process(app);

    QString dataDir = qEnvironmentVariable("CALY_DATA_DIR");
    if (dataDir.isEmpty())
        dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (parser.isSet(resetOpt)) {
        QFile::remove(dataDir + QStringLiteral("/caly.json"));
    }

    Backend backend;
    if (parser.isSet(demoOpt) && !backend.onboarded()) {
        backend.completeOnboarding(QStringLiteral("Killy"), QStringLiteral("€"),
                                   2400.0, 500.0, true);
    }

    if (parser.isSet(selfOpt)) {
        int failures = 0;
        auto check = [&failures](const char *name, bool ok) {
            fprintf(stderr, "%s %s\n", ok ? "PASS" : "FAIL", name);
            if (!ok)
                ++failures;
        };

        backend.resetAll();
        check("reset clears onboarding", !backend.onboarded());
        check("reset clears transactions", backend.allTransactions().isEmpty());

        backend.completeOnboarding(QStringLiteral("Test"), QStringLiteral("€"),
                                   2000.0, 500.0, false);
        check("onboarding sets flag", backend.onboarded());
        check("onboarding stores name", backend.userName() == QStringLiteral("Test"));
        check("onboarding without seed stays empty", backend.allTransactions().isEmpty());

        const QString today = backend.todayIso();
        check("add income", backend.addTransaction(today, 100.0, QStringLiteral("income"),
                                                   QStringLiteral("Stipendio"), QStringLiteral("")));
        check("add expense", backend.addTransaction(today, 40.0, QStringLiteral("expense"),
                                                    QStringLiteral("Cibo"), QStringLiteral("")));
        check("two transactions stored", backend.allTransactions().size() == 2);
        check("day lookup", backend.transactionsForDay(today).size() == 2);

        const QVariantMap sum = backend.monthSummary(backend.currentYear(), backend.currentMonth());
        check("month income", qFuzzyCompare(sum.value("income").toDouble(), 100.0));
        check("month expense", qFuzzyCompare(sum.value("expense").toDouble(), 40.0));
        check("month net", qFuzzyCompare(sum.value("net").toDouble(), 60.0));

        const QVariantList all = backend.allTransactions();
        QString victim;
        for (const auto &v : all) {
            const QVariantMap m = v.toMap();
            if (m.value("type").toString() == QStringLiteral("income"))
                victim = m.value("id").toString();
        }
        check("transaction id present", !victim.isEmpty());
        check("remove transaction", backend.removeTransaction(victim));
        check("one transaction left", backend.allTransactions().size() == 1);

        const QString exported = backend.exportJson();
        check("export writes file", !exported.isEmpty() && QFileInfo::exists(exported));

        backend.resetAll();
        check("final reset clears transactions", backend.allTransactions().isEmpty());
        check("final reset clears flag", !backend.onboarded());

        fprintf(stderr, "selftest: %d failure(s)\n", failures);
        return failures == 0 ? 0 : 1;
    }

    QQuickStyle::setStyle(QStringLiteral("Basic"));

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("backend"), &backend);
    engine.rootContext()->setContextProperty(QStringLiteral("startupStep"),
                                             parser.value(stepOpt).toInt());
    engine.rootContext()->setContextProperty(QStringLiteral("startupPage"),
                                             parser.value(pageOpt).toInt());
    engine.rootContext()->setContextProperty(QStringLiteral("startupDialog"),
                                             parser.isSet(dialogOpt));
    engine.rootContext()->setContextProperty(QStringLiteral("startupDay"),
                                             parser.isSet(dayOpt));
    engine.rootContext()->setContextProperty(QStringLiteral("startupAutopilot"),
                                             parser.isSet(autoOpt));
    engine.rootContext()->setContextProperty(QStringLiteral("startupAutoAdd"),
                                             parser.isSet(autoAddOpt));
    engine.rootContext()->setContextProperty(QStringLiteral("startupAutoDelete"),
                                             parser.isSet(autoDelOpt));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                     []() { fprintf(stderr, "QML object creation failed\n"); QCoreApplication::exit(1); }, Qt::QueuedConnection);
    QObject::connect(&engine, &QQmlApplicationEngine::warnings, &app,
                     [](const QList<QQmlError> &warnings) {
                         for (const auto &w : warnings)
                             fprintf(stderr, "QML warning: %s\n", qPrintable(w.toString()));
                     });

    engine.loadFromModule("Caly", "Main");
    if (engine.rootObjects().isEmpty())
        return 1;

    if (parser.isSet(shotOpt)) {
        const QString path = parser.value(shotOpt);
        const int delay = parser.value(delayOpt).toInt();
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
        if (window) {
            QTimer::singleShot(delay, &app, [window, path]() {
                const QImage img = window->grabWindow();
                if (!img.isNull()) {
                    QDir().mkpath(QFileInfo(path).absolutePath());
                    img.save(path);
                }
                QCoreApplication::quit();
            });
        }
    }

    return app.exec();
}
