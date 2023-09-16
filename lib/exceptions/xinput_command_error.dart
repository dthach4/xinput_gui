class XInputCommandError extends Error {

  final int? exitCode;

  XInputCommandError({this.exitCode}): super();

}
