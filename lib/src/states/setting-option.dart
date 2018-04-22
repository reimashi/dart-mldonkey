class SettingOption {
  final String section;
  final String description;
  final String name;
  final String type;
  final String help;
  final String value;
  final String defaultValue;
  final bool isAdvanced;
  final bool isPlugin;

  SettingOption(this.section, this.description, this.name, this.type, this.help,
      this.value, this.defaultValue, this.isAdvanced, [this.isPlugin = false]);
}
