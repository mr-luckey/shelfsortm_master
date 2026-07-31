"""Cuts the 3D finance/office renders out of their black background and writes
them to assets/images/emojis/finance/ as transparent 256px PNGs."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image
from rembg import remove

ROOT = Path(__file__).resolve().parents[1]
SRC = Path(
    r"C:\Users\engin\.cursor\projects\d-Playstore-shelfsortm-master\assets"
)
DEST = ROOT / "assets" / "images" / "emojis" / "finance"

PREFIX = (
    "c__Users_engin_AppData_Roaming_Cursor_User_workspaceStorage_"
    "74e53c8cdb72892f45b6cabc4b1f3afb_images_"
)

# source stem (without the prefix and the uuid suffix) -> emoji key
NAMES = {
    "notification_or_reminder_concept_with_orange_metallic_bell": "bell",
    "money_bag_with_dollar_sign_personal_finance_savings": "moneybag",
    "orange_document_folder_for_file_management_and_organization": "folder",
    "orange_scroll_of_paper_with_text_lines": "scroll",
    "question_mark": "questionmark",
    "office_document_curved_paper_with_text_lines": "document",
    "personal_finance_savings_concept_with_stacked_coins": "coinstack",
    "retail_purchase_proof_as_stylized_receipt_slip": "receiptslip",
    "wavy_scroll_of_paper_with_text_lines": "wavyscroll",
    "safe_access_solution_with_metallic_orange_lock": "padlock",
    "statistics_bar_chart": "barchart",
    "white_paper_slip_with_black_and_orange_text_lines": "paperslip",
    "spiral_bound_notebook_with_orange_hardcover": "notebook",
    "bar_chart_on_clipboard": "clipboard",
    "bank_building_with_dollar_sign_and_columns": "bank",
    "banking_cash_bundle_with_dollar_symbol_clip": "cashbundle",
    "bitcoin_coin": "bitcoin",
    "calculator_with_large_orange_buttons": "calculator",
    "barrel_of_oil": "oilbarrel",
    "orange_payment_receipt_with_lines_of_text": "receipt",
    "trophy_cup_on_podium_success_and_victory": "trophy",
    "coin": "coin",
    "deposit_safe": "safe",
    "cash_flow_management_concept_with_floating_dollar_banknote": "banknote",
    "data_security_badge_for_online_privacy_with_solid_shield": "shield",
    "digital_paperwork_sheet_with_text_lines": "paperwork",
    "discount_shopping_tag_for_seasonal_sales_and_offers": "pricetag",
    "e_commerce_purchase_summary_with_abstract_receipt_slip": "purchaseslip",
    "light_bulb": "lightbulb",
    "financial_savings_concept_with_money_bag_and_stacked_coins": "savings",
    "empty_shopping_cart_online_ordering_and_checkout": "shoppingcart",
    "educational_physics_magnet_for_classroom_visual_teaching": "magnet",
    "megaphone": "megaphone",
}


def source_for(stem: str) -> str:
    matches = sorted(SRC.glob(f"{PREFIX}{stem}-*.png"))
    if not matches:
        raise FileNotFoundError(stem)
    # The generated names blow past Windows' 260 char limit.
    return "\\\\?\\" + str(matches[0])


def trim_square(img: Image.Image) -> Image.Image:
    a = np.array(img)
    ys, xs = np.where(a[:, :, 3] > 20)
    if len(xs) == 0:
        raise ValueError("empty alpha")
    img = img.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))
    w, h = img.size
    side = int(max(w, h) * 1.08)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(img, ((side - w) // 2, (side - h) // 2), img)
    return canvas


def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    for stem, key in NAMES.items():
        src = source_for(stem)
        cut = remove(Image.open(src).convert("RGB"))
        out = trim_square(cut).resize((256, 256), Image.Resampling.LANCZOS)
        out.save(DEST / f"{key}.png", optimize=True)
        cover = float((np.array(out)[:, :, 3] > 10).mean())
        print(f"{key:14s} alpha={cover:.2f}")
    print(f"wrote {len(NAMES)} files to {DEST}")


if __name__ == "__main__":
    main()
