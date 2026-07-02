import tempfile
import unittest
from pathlib import Path

from lib.agent_github_packages import CommandError, discover_linked_skill, discover_skills, parse_github_import_url, skill_labels


def write_skill(root, rel, name):
    path = root / rel / "SKILL.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        "\n".join(
            [
                "---",
                f"name: {name}",
                f"description: {name} test skill",
                "---",
                "",
            ]
        ),
        encoding="utf-8",
    )


class DiscoverSkillsTests(unittest.TestCase):
    def test_prefers_top_level_skills_over_generated_adapter_copies(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write_skill(root, "skills/ponytail", "ponytail")
            write_skill(root, "skills/ponytail-review", "ponytail-review")
            write_skill(root, ".openclaw/skills/ponytail", "ponytail")
            write_skill(root, ".openclaw/skills/ponytail-review", "ponytail-review")

            skills_path, skills = discover_skills(root)

            self.assertEqual(skills_path, "skills")
            self.assertEqual(sorted(skills), ["ponytail", "ponytail-review"])

    def test_duplicate_names_still_fail_inside_selected_skills_root(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write_skill(root, "skills/one", "one")
            write_skill(root, "skills/group/one", "one")

            with self.assertRaisesRegex(CommandError, "duplicate skill name: one"):
                discover_skills(root)

    def test_discovers_root_skill_md_as_single_skill(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write_skill(root, ".", "herdr")

            skills_path, skills = discover_skills(root)

            self.assertEqual(skills_path, ".")
            self.assertEqual(sorted(skills), ["herdr"])
            self.assertEqual(skills["herdr"], root)

    def test_direct_skill_link_selects_only_that_skill_directory(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write_skill(root, "skills/one", "one")
            write_skill(root, "skills/two", "two")

            skills_path, skills = discover_linked_skill(root, Path("skills/one/SKILL.md"))

            self.assertEqual(skills_path, "skills/one")
            self.assertEqual(sorted(skills), ["one"])

    def test_parses_github_skill_blob_url_for_import(self):
        owner, repo, clone_url, blob_parts = parse_github_import_url(
            "https://github.com/ogulcancelik/herdr/blob/master/SKILL.md"
        )

        self.assertEqual(owner, "ogulcancelik")
        self.assertEqual(repo, "herdr")
        self.assertEqual(clone_url, "https://github.com/ogulcancelik/herdr.git")
        self.assertEqual(blob_parts, ["master", "SKILL.md"])

    def test_root_skill_label_uses_name_not_dot(self):
        labels = skill_labels(["herdr"], {"herdr": {"source_path": "."}})

        self.assertEqual(labels, ["herdr"])


if __name__ == "__main__":
    unittest.main()
