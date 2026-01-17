class UmlInputs {
  const UmlInputs({
    required this.classDiagramPath,
    this.sequenceDiagramPath,
  });

  final String classDiagramPath;
  final String? sequenceDiagramPath;

  bool get hasSequence =>
      sequenceDiagramPath != null && sequenceDiagramPath!.isNotEmpty;
}
