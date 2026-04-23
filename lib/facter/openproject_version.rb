# frozen_string_literal: true

# SPDX-FileCopyrightText: 2026 Vox Pupuli
# SPDX-License-Identifier: GPL-3.0-only

Facter.add(:openproject_version) do
  confine do
    Facter::Core::Execution.which('dpkg-query') || Facter::Core::Execution.which('rpm')
  end

  setcode do
    if Facter::Core::Execution.which('dpkg-query')
      output = Facter::Core::Execution.execute(
        'dpkg-query -W -f \'${Status} ${Version}\' openproject 2>/dev/null',
      )
      if output.match?(%r{^install ok installed })
        # Strip to upstream version: "14.6.3-1730194473..." -> "14.6.3"
        output.sub(%r{^install ok installed }, '').split('-').first
      end
    elsif Facter::Core::Execution.which('rpm')
      output = Facter::Core::Execution.execute(
        'rpm -q --qf \'%{VERSION}\' openproject 2>/dev/null',
      )
      output unless output.match?(%r{not installed})
    end
  end
end
