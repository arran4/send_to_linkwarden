import sys
import re

def bump_version(version_type, current_version):
    # Strip potential comments or whitespace
    clean_version = current_version.split()[0]

    # Regex to parse version: major.minor.patch([-prerelease])?(+build)?
    match = re.match(r'(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z-.]+))?(?:\+([0-9A-Za-z-.]+))?', clean_version)
    if not match:
        raise ValueError(f"Invalid version format: {clean_version}")

    major, minor, patch = map(int, match.group(1, 2, 3))

    # We will ignore the old build number for the increment logic
    # and append +1 for the new version if we are incrementing.

    if version_type == 'major':
        major += 1
        minor = 0
        patch = 0
        new_ver = f"{major}.{minor}.{patch}+1"
    elif version_type == 'minor':
        minor += 1
        patch = 0
        new_ver = f"{major}.{minor}.{patch}+1"
    elif version_type == 'patch':
        patch += 1
        new_ver = f"{major}.{minor}.{patch}+1"
    else:
        # Check if input is a valid version string
        if re.match(r'\d+\.\d+\.\d+(?:-[0-9A-Za-z-.]+)?(?:\+[0-9A-Za-z-.]+)?', version_type):
            new_ver = version_type
            # Ensure it has a build number if the original had one?
            # Or assume the user provided full version string.
            # If user provides 1.2.3, we might want 1.2.3+1.
            # But maybe they provided 1.2.3+5.
            if '+' not in new_ver:
                 new_ver += "+1"
        else:
            raise ValueError(f"Invalid version type or version string: {version_type}")

    return new_ver

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python bump_version.py <version_type>")
        sys.exit(1)

    version_type = sys.argv[1]
    file_path = sys.argv[2] if len(sys.argv) > 2 else 'pubspec.yaml'

    try:
        with open(file_path, 'r') as f:
            content = f.read()

        # Find version line
        version_pattern = re.compile(r'^version:\s+([^\s]+)', re.MULTILINE)
        match = version_pattern.search(content)
        if not match:
            print(f"Could not find version in {file_path}")
            sys.exit(1)

        current_version = match.group(1)
        new_version = bump_version(version_type, current_version)

        # Replace only the version part, keeping the rest of the line (e.g. comments)
        # Actually, my regex `^version:\s+([^\s]+)` captures the version.
        # I want to replace that captured group.

        # We need to construct the replacement string carefully.
        # But simpler: just replace the whole match with "version: <new_version>"
        # Wait, if there are multiple spaces?
        # Let's use string replacement on the match span.

        start, end = match.span(1)
        new_content = content[:start] + new_version + content[end:]

        with open(file_path, 'w') as f:
            f.write(new_content)

        print(f"Updated version from {current_version} to {new_version}")

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
