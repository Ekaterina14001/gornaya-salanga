# -*- coding: utf-8 -*-
"""Generate FT BARS PDF — Cyrillic + yellow highlight vs ДК-Софт original appendix."""
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "FT-SPK-Bars-Kassir-Gornaya-Salanga.pdf"
OUT_DOWNLOADS = Path.home() / "Downloads" / "FT_SPK_Bars_Kassir_Gornaya_Salanga.pdf"

FONT_DIR = Path(r"C:\Windows\Fonts")
FONT_NORMAL = "RuTimes"
FONT_BOLD = "RuTimes-Bold"
HIGHLIGHT = colors.HexColor("#FFF59D")
CONTENT_W = A4[0] - 4 * cm


def register_fonts():
    pdfmetrics.registerFont(TTFont(FONT_NORMAL, str(FONT_DIR / "times.ttf")))
    pdfmetrics.registerFont(TTFont(FONT_BOLD, str(FONT_DIR / "timesbd.ttf")))
    pdfmetrics.registerFontFamily(
        FONT_NORMAL,
        normal=FONT_NORMAL,
        bold=FONT_BOLD,
        italic=FONT_NORMAL,
        boldItalic=FONT_BOLD,
    )


def on_page(canvas, doc):
    canvas.saveState()
    canvas.setFont(FONT_NORMAL, 9)
    canvas.drawCentredString(A4[0] / 2, 1.2 * cm, f"— {doc.page} —")
    canvas.restoreState()


def build_styles():
    base = getSampleStyleSheet()

    def ps(name, **kw):
        d = dict(parent=base["Normal"], fontName=FONT_NORMAL, fontSize=11, leading=14)
        d.update(kw)
        return ParagraphStyle(name, **d)

    return {
        "appendix": ps("appendix"),
        "contract_ref": ps("contract_ref"),
        "title": ps("title", fontName=FONT_BOLD, fontSize=12, leading=15, alignment=TA_CENTER, spaceAfter=6),
        "subtitle": ps("subtitle", alignment=TA_CENTER, spaceAfter=10),
        "h1": ps("h1", fontName=FONT_BOLD, spaceBefore=10, spaceAfter=6),
        "h2": ps("h2", fontName=FONT_BOLD, spaceBefore=8, spaceAfter=4),
        "body": ps("body", alignment=TA_JUSTIFY, spaceAfter=4),
        "bullet": ps("bullet", leftIndent=14, spaceAfter=2),
        "table_cell": ps("table_cell", fontSize=10, leading=12),
        "sign": ps("sign", leading=16, spaceBefore=8),
    }


styles = None
story = []


def wrap_highlight(flowable, highlight: bool):
    if not highlight:
        return flowable
    t = Table([[flowable]], colWidths=[CONTENT_W])
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), HIGHLIGHT),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 4),
                ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    return t


def add_p(text: str, style: str = "body", highlight: bool = False):
    story.append(wrap_highlight(Paragraph(text, styles[style]), highlight))


def add_bullet(text: str, highlight: bool = False):
    add_p(f"• {text}", "bullet", highlight)


def table_two_col(rows, highlight_rows=None):
    """highlight_rows: set of row indices (0-based) to yellow-fill."""
    highlight_rows = highlight_rows or set()
    data = [[Paragraph(a, styles["table_cell"]), Paragraph(b, styles["table_cell"])] for a, b in rows]
    t = Table(data, colWidths=(7.5 * cm, 9 * cm))
    style_commands = [
        ("FONT", (0, 0), (-1, -1), FONT_NORMAL, 10),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LINEBELOW", (0, 0), (-1, 0), 0.5, colors.black),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]
    for ri in highlight_rows:
        style_commands.append(("BACKGROUND", (0, ri), (-1, ri), HIGHLIGHT))
    t.setStyle(TableStyle(style_commands))
    story.append(t)


def build_story():
    global story
    story = []

    add_p("Приложение № 1", "appendix")
    add_p("к Договору № ДС-165 от 08.10.2026", "contract_ref")
    story.append(Spacer(1, 0.35 * cm))
    add_p("Функциональные требования к доработке модуля СПК", "title")
    add_p("Барс.Кассир", "title")
    add_p(
        "Интеграция с бонусной системой курорта «Горная Саланга» по протоколу UDS",
        "subtitle",
    )
    story.append(Spacer(1, 0.25 * cm))

    add_p("1 Предмет и состав работ", "h1")
    add_p("1.1. Предмет", "h2", highlight=True)
    add_p(
        "Исполнитель выполняет доработку модуля СПК Барс.Кассир для взаимодействия "
        "с бонусной системой Заказчика через штатную интеграцию по протоколу UDS. "
        "Далее в настоящем документе под кассовым ПО понимается модуль СПК Барс.Кассир.",
        "body",
    )
    add_p("1.2. В состав работ Исполнителя входят:", "h2", highlight=True)
    bullets_12 = [
        (
            "применение заданных в настройках адреса сервера, авторизации и таймаута запросов;",
            True,
        ),
        (
            "запрет обращений к api.uds.app, в том числе переключения на него при ошибке;",
            True,
        ),
        (
            "реализация частичного возврата по исходной бонусной операции при возврате конкретной позиции чека;",
            False,
        ),
        ("реализация полного возврата чека (все позиции);", True),
        (
            "сохранение данных для связи покупки и возвратов, обработка ответов и ошибок сервера;",
            False,
        ),
        (
            "передача Заказчику инструкции по проверке результата операции и безопасному повтору запроса "
            "при неопределённом ответе сервера.",
            True,
        ),
    ]
    for text, hl in bullets_12:
        add_bullet(text, hl)

    add_p("2 Подключение к бонусной системе", "h1")
    add_p(
        "Параметры подключения. Кассовое ПО должно использовать следующие параметры интеграции UDS.",
        "body",
    )
    table_two_col(
        [
            ("<b>Параметр</b>", "<b>Требуемое значение</b>"),
            ("Базовый адрес API", "https://api.salanga.ru/api/partner/v2"),
            ("Авторизация", "HTTP Basic, пара «ИД компании : API-ключ»"),
            ("Таймаут одного запроса", "15 секунд"),
            ("ИД компании и API-ключ", "предоставляются Заказчиком для настройки кассы"),
        ],
        highlight_rows={4},
    )
    story.append(Spacer(1, 0.15 * cm))
    add_p(
        "Адрес API, реквизиты авторизации и таймаут должны считываться из настроек интеграции. "
        "Применение изменённых настроек допускается после повторной инициализации интеграции "
        "или перезапуска кассового ПО.",
        "body",
    )
    add_p("Направление запросов.", "h2")
    add_p(
        "Получение настроек программы лояльности, поиск гостя, предварительный расчёт покупки, "
        "проведение покупки, получение статуса операции, полный и частичный возврат должны "
        "выполняться через настроенный сервер Заказчика. При указанном адресе сервера обращения "
        "к api.uds.app, в том числе переключение на него при ошибке, не допускаются.",
        "body",
        highlight=True,
    )
    add_p("Инициализация.", "h2")
    add_p(
        "При инициализации интеграции касса должна запрашивать настройки программы лояльности. "
        "При ошибке авторизации, недоступности сервера или истечении таймаута касса должна "
        "сообщать об ошибке и не отображать неподтверждённую бонусную операцию как успешно выполненную.",
        "body",
    )

    add_p("3 Требования к проведению покупки", "h1")
    add_p(
        "При подключении к серверу Заказчика должна обеспечиваться следующая последовательность:",
        "body",
    )
    steps_3 = [
        ("Кассир формирует чек и считывает QR-код гостя из приложения Заказчика.", False),
        ("Касса запрашивает данные гостя и предварительный расчёт покупки.", False),
        (
            "Касса отображает полученные от сервера сведения: доступные к списанию бонусы, "
            "скидку (лимит лояльности) и количество бонусов к начислению.",
            True,
        ),
        (
            "Кассир применяет бонусы в пределах доступной суммы. Оставшаяся часть покупки "
            "оплачивается штатными средствами модуля «СПК Барс.Кассир».",
            False,
        ),
        (
            "При расчёте на кассе в бонусную систему передаётся операция покупки. "
            "Сведения об операции печатаются штатными средствами модуля «СПК Барс.Кассир».",
            False,
        ),
    ]
    for i, (t, hl) in enumerate(steps_3, 1):
        add_p(f"{i}. {t}", "body", hl)

    add_p(
        "Правила начисления, ограничения списания и размер скидки определяются сервером Заказчика. "
        "Передача покупки в бонусную систему выполняется при расчёте на кассе. Скидка (лимит лояльности), "
        "полученная от сервера, не должна учитываться кассой как сумма списанных бонусов.",
        "body",
        highlight=True,
    )
    add_p(
        "При проведении покупки касса передаёт уникальный код операции (поле nonce в протоколе UDS "
        "и/или номер чека — по согласованной схеме). При повторной отправке запроса с тем же кодом "
        "после сбоя связи касса обрабатывает ответ сервера и не фиксирует локально вторую бонусную "
        "операцию без подтверждения сервера.",
        "body",
        highlight=True,
    )
    add_p(
        "Сохранение исходной операции. Для успешно проведённой бонусной покупки касса должна "
        "сохранять идентификатор операции сервера и связь с исходным чеком. Должны сохраняться "
        "данные, позволяющие определить возвращаемую позицию и относящиеся к ней суммы. "
        "Эти данные должны быть доступны для частичного и полного возврата, в том числе после "
        "перезапуска кассового ПО.",
        "body",
        highlight=True,
    )

    add_p("4 Требования к частичному и полному возврату по позициям чека", "h1", highlight=True)
    blocks_4 = [
        (
            "Идентификация покупки.",
            "При оформлении возврата конкретной позиции касса должна определять исходный чек "
            "и связанную с ним бонусную операцию, а затем передавать идентификатор этой операции "
            "серверу Заказчика. Повторное предъявление QR-кода гостя не требуется.",
            False,
        ),
        (
            "Возврат позиции.",
            "Кассир выбирает позицию или позиции для возврата. Касса должна автоматически "
            "передавать запрос частичного возврата по исходной бонусной операции в сумме, "
            "соответствующей выбранной позиции, и обрабатывать ответ сервера.",
            False,
        ),
        (
            "Расчёт возврата по позиции.",
            "Передаваемая сумма должна соответствовать возвращаемой позиции и данным ответа сервера, "
            "учитывать применённые к ней скидки и бонусную оплату.",
            True,
        ),
        (
            "Учёт возвращённых позиций.",
            "При последовательных возвратах отдельных позиций одного чека касса должна учитывать "
            "ранее успешно выполненные возвраты. Каждая операция возврата должна относиться "
            "к конкретной позиции. Повторный возврат уже возвращённой позиции не допускается.",
            False,
        ),
        (
            "Возврат позиции без списания бонусов.",
            "Если по возвращаемой позиции начислялись бонусы, но списания бонусов не было, "
            "касса должна передавать частичный возврат для отмены начисления по этой позиции. "
            "Нулевая сумма списания не должна приводить к пропуску бонусного возврата.",
            False,
        ),
        (
            "Денежная и бонусная части.",
            "Возврат денежных средств выполняется штатными средствами модуля «СПК Барс.Кассир» "
            "с учётом исходной оплаты возвращаемой позиции. Относящиеся к этой позиции списанные бонусы "
            "восстанавливаются на бонусном счёте через взаимодействие с сервером и не подменяются "
            "выдачей денежных средств. Скидка не должна учитываться как сумма списанных бонусов.",
            True,
        ),
        (
            "Полный возврат чека.",
            "При возврате всех позиций чека касса должна выполнить бонусный возврат по исходной "
            "операции в полном объёме (одним запросом или последовательностью частичных возвратов "
            "по позициям — по согласованной схеме взаимодействия с сервером).",
            True,
        ),
        (
            "Подтверждение и сохранение результата.",
            "Частичный или полный бонусный возврат считается успешным только при подтверждении "
            "сервером Заказчика. Касса должна сохранять связь выполненного возврата с исходной "
            "покупкой и конкретной возвращённой позицией. Повторное выполнение уже подтверждённого "
            "возврата не должно повторно изменять бонусный счёт на стороне кассового ПО без "
            "нового подтверждения сервера.",
            True,
        ),
    ]
    for title, text, hl in blocks_4:
        add_p(title, "h2", hl and title == "Полный возврат чека.")
        add_p(text, "body", hl)

    add_p("5 Обработка ошибок", "h1")
    add_p("Ошибка возврата.", "h2")
    add_p(
        "При отказе сервера, сетевой ошибке или истечении таймаута касса должна выводить "
        "сообщение о том, что бонусный возврат не подтверждён. Отсутствие ответа не должно "
        "интерпретироваться как успешное выполнение или как достоверный отказ сервера "
        "от выполнения операции.",
        "body",
    )
    add_p("Неопределённый результат.", "h2")
    add_p(
        "Если запрос мог быть выполнен сервером, но подтверждение не получено, повторная "
        "отправка допускается только после установления результата предыдущего запроса. "
        "Проверка выполняется по данным кассы и ответам сервера (в том числе запрос статуса "
        "операции по протоколу UDS). Порядок проверки и безопасного повторного выполнения "
        "должен быть описан в передаваемой Исполнителем инструкции. Автоматическая фоновая "
        "очередь повторных запросов не требуется.",
        "body",
        highlight=True,
    )
    add_p("Отсутствие исходной операции.", "h2")
    add_p(
        "При отсутствии сохранённого идентификатора покупки либо при ответе сервера "
        "об отсутствии исходной операции касса должна сообщать об ошибке и не выполнять "
        "возврат по произвольно выбранной бонусной операции.",
        "body",
    )

    story.append(Spacer(1, 0.8 * cm))
    add_p("От Исполнителя:", "sign")
    add_p("ООО «ДК-Софт»", "sign")
    story.append(Spacer(1, 0.5 * cm))
    add_p("_____________________ / А.А. Шевченко /", "sign")
    story.append(Spacer(1, 0.4 * cm))
    add_p("От Заказчика:", "sign")
    add_p("ООО «Горная Саланга»", "sign")
    story.append(Spacer(1, 0.5 * cm))
    add_p("_____________________ / Д.В. Андрющенко /", "sign")


def main():
    global styles
    register_fonts()
    styles = build_styles()
    build_story()
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=A4,
        leftMargin=2 * cm,
        rightMargin=2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
        title="FT SPK Bars Kassir",
    )
    doc.build(story, onFirstPage=on_page, onLaterPages=on_page)
    import shutil

    shutil.copy2(OUT, OUT_DOWNLOADS)
    print(f"Written: {OUT}")
    print(f"Copied:  {OUT_DOWNLOADS}")


if __name__ == "__main__":
    main()
