# @summary sets up system requirements
#
# @api private
class openproject::system_requirements {
  stdlib::ensure_packages(
    lookup('openproject::system_requirements')
  )

  if $openproject::enable_full_text_extract {
    stdlib::ensure_packages(
      lookup('openproject::full_text_extract_packages')
    )
  }
}
