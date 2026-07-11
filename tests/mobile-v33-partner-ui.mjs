import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';

const root = path.resolve('apps/partner_flutter');
const read = (p) => fs.readFileSync(path.join(root, p), 'utf8');
const must = (p, values) => {
  const text = read(p);
  for (const value of values) assert.ok(text.includes(value), `${p} missing ${value}`);
};

must('lib/screens/partner_shell.dart', ['DashboardScreen', 'DriversScreen', 'EarningsScreen', 'ProfileScreen', 'NavigationBar']);
must('lib/screens/dashboard_screen.dart', ['showDateRangePicker', 'monthlyTarget', 'onlineDrivers', 'LinearProgressIndicator']);
must('lib/screens/drivers_screen.dart', ['ChoiceChip', 'ATTENTION', 'TOP', 'DriverDetailScreen', 'visibleDrivers']);
must('lib/screens/driver_detail_screen.dart', ['ENCOURAGE', 'WARNING', 'TRAINING', 'reportAdmin']);
must('lib/screens/earnings_screen.dart', ['withdrawable', 'nextSettlementDate', 'withdrawLocked']);
must('lib/screens/profile_screen.dart', ["'en'", "'bn'", "'hi'", 'setLanguage']);
must('lib/core/partner_strings.dart', ["'en':", "'bn':", "'hi':", 'promoterDashboard', 'areaDashboard', 'withdrawLocked']);
must('lib/state/partner_controller.dart', ['DateTimeRangeValue', 'visibleDrivers', 'setDriverFilter', 'setDriverQuery', 'setLanguage']);
must('pubspec.yaml', ['version: 3.3.0+33']);

const strings = read('lib/core/partner_strings.dart');
for (const code of ['en', 'bn', 'hi']) assert.ok(strings.includes(`'${code}': {`));
console.log('v3.3 partner/area promoter UI contract passed');
