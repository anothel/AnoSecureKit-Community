# SPDX-License-Identifier: MPL-2.0

"""Validate the gcovr report in the build directory or an extracted artifact."""

import argparse
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit
from xml.etree import ElementTree


class ReportPage(HTMLParser):
    def __init__(self, path):
        super().__init__()
        self.links = []
        self.anchors = set()
        self.feed(path.read_text(encoding="utf-8"))
        self.close()

    def handle_starttag(self, tag, attributes):
        for name, value in attributes:
            if not value:
                continue
            if name in ("href", "src"):
                self.links.append(value)
            if name == "id" or (tag == "a" and name == "name"):
                self.anchors.add(value)


def validate_report(root):
    index = root / "anosecurekit.html"
    functions_page = root / "anosecurekit.functions.html"
    xml = root / "coverage.xml"
    if not index.is_file():
        raise SystemExit(f"Missing coverage index: {index}")
    try:
        if ElementTree.parse(xml).getroot().tag != "coverage":
            raise SystemExit(f"Expected a <coverage> root in {xml}")
    except (OSError, ElementTree.ParseError) as error:
        raise SystemExit(f"Cannot read coverage XML: {error}")

    pages = {path: ReportPage(path) for path in sorted(root.rglob("*.html"))}
    source_pages = set()
    errors = []
    link_count = 0
    fragment_count = 0
    for path, page in pages.items():
        for link in page.links:
            url = urlsplit(link)
            if url.scheme or url.netloc:
                continue

            link_count += 1
            target = (path.parent / unquote(url.path)).resolve() if url.path else path
            fragment = unquote(url.fragment)
            if root not in target.parents or not target.is_file():
                errors.append(f"{path.relative_to(root)}: missing report target {link}")
                continue
            if fragment and target in pages:
                fragment_count += 1
                if fragment not in pages[target].anchors:
                    errors.append(f"{path.relative_to(root)}: missing report anchor {link}")
            if path == index and target in pages and target not in (index, functions_page):
                source_pages.add(target)

    if not source_pages:
        errors.append("Coverage index has no links to source detail pages")
    if errors:
        raise SystemExit("\n".join(errors))

    print(
        f"Validated coverage.xml and {len(pages)} HTML pages "
        f"({len(source_pages)} source detail pages linked from the index), "
        f"{link_count} relative links, and {fragment_count} HTML fragments"
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report_directory", type=Path)
    args = parser.parse_args()
    validate_report(args.report_directory.resolve())
