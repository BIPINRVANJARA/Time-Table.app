class CollegeStructureService {
  static const List<String> branches = [
    'Computer Engineering',
    'Information Technology',
    'Mechanical Engineering',
    'Civil Engineering',
    'Electrical Engineering',
    'Electronics & Telecommunication',
    'Artificial Intelligence & Data Science',
  ];

  static const List<String> semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
  ];

  static const List<String> divisions = [
    'A',
    'B',
    'C',
  ];

  static const List<String> batches = [
    'A1', 'A2', 'A3', 'A4',
    'B1', 'B2', 'B3', 'B4',
    'C1', 'C2', 'C3', 'C4',
  ];

  // Helper to get semester number as string (e.g., 'Semester 1' -> '1')
  static String getSemesterNumber(String semesterStr) {
    return semesterStr.split(' ').last;
  }

  // Get batches for a specific division
  static List<String> getBatchesForDivision(String division) {
    if (division == 'A') return ['A1', 'A2', 'A3', 'A4'];
    if (division == 'B') return ['B1', 'B2', 'B3', 'B4'];
    if (division == 'C') return ['C1', 'C2', 'C3', 'C4'];
    return [];
  }
}
