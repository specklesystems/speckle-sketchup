import re
import sys


def patch_connector(tag):
    """Patches the connector version within the connector file"""
    rb_file = "speckle_connector.rb"

    with open(rb_file, "r") as file:
        lines = file.readlines()

        for (index, line) in enumerate(lines):
            if 'CONNECTOR_VERSION = ' in line:
                lines[index] = f'    CONNECTOR_VERSION = "{tag}"\n'
                print(f"Patched connector version number in {rb_file}")
                break

        with open(rb_file, "w") as file:
            file.writelines(lines)


def patch_installer(tag):
    """Patches the installer with the correct connector version"""
    iss_file = "speckle-sharp-ci-tools/sketchup.iss"

    with open(iss_file, "r") as file:
        lines = file.readlines()
        lines.insert(11, f'#define AppVersion "{tag}"\n')

        with open(iss_file, "w") as file:
            file.writelines(lines)
            print(f"Patched installer with connector v{tag}")




def main():
    if len(sys.argv) < 2:
        return

    tag = sys.argv[1]
    if not re.match(r"[0-9]+(\.[0-9]+)*$", tag):
        raise ValueError(f"Invalid tag provided: {tag}")

    print(f"Patching version: {tag}")
    patch_connector(tag)
    patch_installer(tag)


if __name__ == "__main__":
    main()
