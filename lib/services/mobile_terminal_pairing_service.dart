import '../domain/models/mobile_terminal_pairing_bond.dart';

/// Service managing persistent device trust bonds and automated walk-by proximity punching
class MobileTerminalPairingService {
  final Map<String, MobileTerminalPairingBond> _bonds = {};

  List<MobileTerminalPairingBond> get bondedTerminals =>
      _bonds.values.toList();

  MobileTerminalPairingBond createBond({
    required String terminalId,
    required String terminalName,
    required String employeeId,
    required String enterpriseId,
    required String publicDeviceKey,
  }) {
    final bond = MobileTerminalPairingBond(
      bondId: 'BOND_${DateTime.now().millisecondsSinceEpoch}',
      terminalId: terminalId,
      terminalName: terminalName,
      employeeId: employeeId,
      enterpriseId: enterpriseId,
      publicDeviceKey: publicDeviceKey,
      autoPunchOnProximity: true,
      autoPunchCooldownSeconds: 300,
      pairedAt: DateTime.now(),
    );
    _bonds[terminalId] = bond;
    return bond;
  }

  /// Triggers proximity auto-punch if bond exists and cooldown satisfied
  bool processWalkByPunch(String terminalId) {
    final bond = _bonds[terminalId];
    if (bond == null || !bond.canAutoPunchNow()) {
      return false;
    }

    _bonds[terminalId] = MobileTerminalPairingBond(
      bondId: bond.bondId,
      terminalId: bond.terminalId,
      terminalName: bond.terminalName,
      employeeId: bond.employeeId,
      enterpriseId: bond.enterpriseId,
      publicDeviceKey: bond.publicDeviceKey,
      autoPunchOnProximity: bond.autoPunchOnProximity,
      autoPunchCooldownSeconds: bond.autoPunchCooldownSeconds,
      pairedAt: bond.pairedAt,
      lastAutoPunchedAt: DateTime.now(),
    );

    return true;
  }

  void unbondTerminal(String terminalId) {
    _bonds.remove(terminalId);
  }
}
