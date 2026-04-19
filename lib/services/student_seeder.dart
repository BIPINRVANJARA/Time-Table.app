import 'package:flutter/material.dart';
import '../models/student.dart';
import 'student_service.dart';

class StudentSeeder {
  static const List<Map<String, dynamic>> _sem4Students = [
    {"sr_no": 1, "roll_no": "246240316001", "name": "AAYUSHKUMAR", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 2, "roll_no": "246240316002", "name": "AGHERA DISHANTKUMAR RAJESHBHAI", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 3, "roll_no": "246240316006", "name": "BANDI MUJAMMIL USMANGANI", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 4, "roll_no": "246240316010", "name": "BHAT ARYAN KARSHANBHAI", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 5, "roll_no": "246240316011", "name": "BHATIYA KAVYANG ABHISHEKBHAI", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 6, "roll_no": "246240316012", "name": "BHAVSAR AKSH ASUTOSH", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 7, "roll_no": "246240316013", "name": "BHAVSAR KIRTAN PIYUSHKUMAR", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 8, "roll_no": "246240316017", "name": "CHAUDHARY HENIL BECHARBHAI", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 9, "roll_no": "246240316019", "name": "CHAUHAN DHRUMIL BHARATBHAI", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 10, "roll_no": "246240316021", "name": "CHAUHAN KARM HIRENKUMAR", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 11, "roll_no": "246240316022", "name": "CHAUHAN MEHULSINH KAPURSINH", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 12, "roll_no": "246240316023", "name": "CHAUHAN NIKHIL MAHESHBHAI", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 13, "roll_no": "246240316026", "name": "CHAUHAN VED CHETANKUMAR", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 14, "roll_no": "246240316027", "name": "CHENVA PARESHKUMAR BHARATBHAI", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 15, "roll_no": "246240316028", "name": "DARJI JIMEE HARESHKUMAR", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 16, "roll_no": "246240316029", "name": "DARJI BHAVIK NILESHBHAI", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 17, "roll_no": "246240316034", "name": "DHIRWANI HARSHIL MANOJKUMAR", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 18, "roll_no": "246240316035", "name": "GADHAWALA MO.RAZA MO.SOEB", "gender": "M", "batch": "A1", "class": "DIV A"},
    {"sr_no": 19, "roll_no": "246240316036", "name": "GANDHI KAVYA ASHISH", "gender": "F", "batch": "A1", "class": "DIV A"},
    {"sr_no": 20, "roll_no": "246240316038", "name": "GAUSWAMI BHAUTIKGIRI SHAILESHGIRI", "gender": "M", "batch": "A1", "class": "DIV A"},

    {"sr_no": 1, "roll_no": "246240316039", "name": "GONGA YASH JITENDRABHAI", "gender": "M", "batch": "A2", "class": "DIV A"},
    {"sr_no": 2, "roll_no": "246240316040", "name": "GOSWAMI MEETKUMAR BHAVESHPURI", "gender": "M", "batch": "A2", "class": "DIV A"},
    {"sr_no": 3, "roll_no": "246240316042", "name": "GOSWAMI TANMAYKUMAR ALPESHPURI", "gender": "M", "batch": "A2", "class": "DIV A"},
    {"sr_no": 4, "roll_no": "246240316043", "name": "HARSH GORANI", "gender": "M", "batch": "A2", "class": "DIV A"},
    {"sr_no": 5, "roll_no": "246240316044", "name": "JANGIR GOURAVKUMAR GHANSHYAM", "gender": "M", "batch": "A2", "class": "DIV A"},
    {"sr_no": 6, "roll_no": "246240316045", "name": "JANGIR GOUTAMKUMAR GHANSHYAM", "gender": "M", "batch": "A2", "class": "DIV A"},
    {"sr_no": 7, "roll_no": "246240316046", "name": "JOSHI AASHMI MITESH", "gender": "F", "batch": "A2", "class": "DIV A"},
    {"sr_no": 8, "roll_no": "246240316047", "name": "KADIYA NEHAL PARESHKUMAR", "gender": "F", "batch": "A2", "class": "DIV A"},
    {"sr_no": 9, "roll_no": "246240316049", "name": "KANZARIYA TRUSHAL KARSHANBHAI", "gender": "M", "batch": "A2", "class": "DIV A"},
    {"sr_no": 10, "roll_no": "246240316050", "name": "KHANT NILESHKUMAR PARESHBHAI", "gender": "M", "batch": "A2", "class": "DIV A"},
    {"sr_no": 11, "roll_no": "246240316051", "name": "KHANT PIYUSHBHAI VINODBHAI", "gender": "M", "batch": "A2", "class": "DIV A"},
    {"sr_no": 12, "roll_no": "246240316052", "name": "KURESHI MOH. AYAANKHAN SARFARAJKHAN", "gender": "M", "batch": "A2", "class": "DIV A"},
    {"sr_no": 13, "roll_no": "246240316053", "name": "KURMI PRIYANKA SHAILENDRA", "gender": "F", "batch": "A2", "class": "DIV A"},
    {"sr_no": 14, "roll_no": "246240316054", "name": "LUHAR MAHAMMADSAFVAN SAUKATBHAI", "gender": "M", "batch": "A2", "class": "DIV A"},
    {"sr_no": 15, "roll_no": "246240316055", "name": "LUHAR MOHMADFARHAN AARIFHUSEN", "gender": "M", "batch": "A2", "class": "DIV A"},
    {"sr_no": 16, "roll_no": "246240316057", "name": "MAHETA RAJ HEMANTBHAI", "gender": "M", "batch": "A2", "class": "DIV A"},
    {"sr_no": 17, "roll_no": "246240316059", "name": "MALI MEGHALKUMAR MAHESHBHAI", "gender": "M", "batch": "A2", "class": "DIV A"},
    {"sr_no": 18, "roll_no": "246240316060", "name": "MANKNUSHIYA IRSHADALI HAIDARALI", "gender": "M", "batch": "A2", "class": "DIV A"},
    {"sr_no": 19, "roll_no": "246240316061", "name": "MANSURI AVEJ IKBALBHAI", "gender": "M", "batch": "A2", "class": "DIV A"},
    {"sr_no": 20, "roll_no": "246240316063", "name": "MASU AHMADBHAI HAFIZBHAI", "gender": "M", "batch": "A2", "class": "DIV A"},

    {"sr_no": 1, "roll_no": "246240316065", "name": "MEHTA ANUJ PARESHKUMAR", "gender": "M", "batch": "A3", "class": "DIV A"},
    {"sr_no": 2, "roll_no": "246240316067", "name": "MESARIYA HIMANSHI", "gender": "F", "batch": "A3", "class": "DIV A"},
    {"sr_no": 3, "roll_no": "246240316069", "name": "MISTRY TANMAY RITESHKUMAR", "gender": "M", "batch": "A3", "class": "DIV A"},
    {"sr_no": 4, "roll_no": "246240316070", "name": "MODASIYA MAHMAD AYAN MUKHTAR AHEMAD", "gender": "M", "batch": "A3", "class": "DIV A"},
    {"sr_no": 5, "roll_no": "246240316073", "name": "NAGARACHI DRUVBHAI JAYESHBHAI", "gender": "M", "batch": "A3", "class": "DIV A"},
    {"sr_no": 6, "roll_no": "246240316074", "name": "NAYI ASTHABEN RAMESHBHAI", "gender": "F", "batch": "A3", "class": "DIV A"},
    {"sr_no": 7, "roll_no": "246240316075", "name": "OD BHAGIRATHKUMAR NARENDRABHAI", "gender": "M", "batch": "A3", "class": "DIV A"},
    {"sr_no": 8, "roll_no": "246240316076", "name": "PANCHAL DISHA GOVINDBHAI", "gender": "F", "batch": "A3", "class": "DIV A"},
    {"sr_no": 9, "roll_no": "246240316077", "name": "PANCHAL DISHABEN BHAVESHBHAI", "gender": "F", "batch": "A3", "class": "DIV A"},
    {"sr_no": 10, "roll_no": "246240316078", "name": "PANCHAL JAINAM PANKAJBHAI", "gender": "M", "batch": "A3", "class": "DIV A"},
    {"sr_no": 11, "roll_no": "246240316081", "name": "PANCHAL RUDRA RAJEEVKUMAR", "gender": "M", "batch": "A3", "class": "DIV A"},
    {"sr_no": 12, "roll_no": "246240316082", "name": "PANCHAL SHREYA VIPULKUMAR", "gender": "F", "batch": "A3", "class": "DIV A"},
    {"sr_no": 13, "roll_no": "246240316083", "name": "PANCHAL SUJALKUMAR NAGINBHAI", "gender": "M", "batch": "A3", "class": "DIV A"},
    {"sr_no": 14, "roll_no": "246240316086", "name": "PANDYA BHARGAVKUMAR ISHVARBHAI", "gender": "M", "batch": "A3", "class": "DIV A"},
    {"sr_no": 15, "roll_no": "246240316088", "name": "PANDYA RUDRA MUKESHBHAI", "gender": "M", "batch": "A3", "class": "DIV A"},
    {"sr_no": 16, "roll_no": "246240316089", "name": "PARMAR HARSH JANAKKUMAR", "gender": "M", "batch": "A3", "class": "DIV A"},
    {"sr_no": 17, "roll_no": "246240316092", "name": "PARMAR VARSHIL JAYESHKUMAR", "gender": "M", "batch": "A3", "class": "DIV A"},
    {"sr_no": 18, "roll_no": "246240316093", "name": "PATEL ARPITKUMAR RAJESHBHAI", "gender": "M", "batch": "A3", "class": "DIV A"},
    {"sr_no": 19, "roll_no": "246240316095", "name": "PATEL DEVANSI DAHYABHAI", "gender": "F", "batch": "A3", "class": "DIV A"},
    {"sr_no": 20, "roll_no": "246240316099", "name": "PATEL DIRGH RAKESHKUMAR", "gender": "M", "batch": "A3", "class": "DIV A"},

    {"sr_no": 1, "roll_no": "246240316101", "name": "PATEL HARSHIL HARSHADBHAI", "gender": "M", "batch": "B1", "class": "DIV B"},
    {"sr_no": 2, "roll_no": "246240316103", "name": "PATEL HETKUMAR SURESHBHAI", "gender": "M", "batch": "B1", "class": "DIV B"},
    {"sr_no": 3, "roll_no": "246240316104", "name": "PATEL HETVIBEN PRAMODBHAI", "gender": "F", "batch": "B1", "class": "DIV B"},
    {"sr_no": 4, "roll_no": "246240316110", "name": "PATEL KASHISH SHAILESHKUMAR", "gender": "F", "batch": "B1", "class": "DIV B"},
    {"sr_no": 5, "roll_no": "246240316113", "name": "PATEL KRISHA HITENDRABHAI", "gender": "F", "batch": "B1", "class": "DIV B"},
    {"sr_no": 6, "roll_no": "246240316115", "name": "PATEL KRISHNAKUMAR DIPAKKUMAR", "gender": "M", "batch": "B1", "class": "DIV B"},
    {"sr_no": 7, "roll_no": "246240316117", "name": "PATEL MUDRA DHARMENDRAKUMAR", "gender": "F", "batch": "B1", "class": "DIV B"},
    {"sr_no": 8, "roll_no": "246240316118", "name": "PATEL NIHALI JIGNESHBHAI", "gender": "F", "batch": "B1", "class": "DIV B"},
    {"sr_no": 9, "roll_no": "246240316120", "name": "PATEL PARINIDHI JIGNESHBHAI", "gender": "F", "batch": "B1", "class": "DIV B"},
    {"sr_no": 10, "roll_no": "246240316122", "name": "PATEL PRANJAL SUDHIRBHAI", "gender": "F", "batch": "B1", "class": "DIV B"},
    {"sr_no": 11, "roll_no": "246240316124", "name": "PATEL RUHAN PARESHKUMAR", "gender": "M", "batch": "B1", "class": "DIV B"},
    {"sr_no": 12, "roll_no": "246240316126", "name": "PATEL SUJAL BIPINBHAI", "gender": "M", "batch": "B1", "class": "DIV B"},
    {"sr_no": 13, "roll_no": "246240316128", "name": "PATEL VEDANTKUMAR MUKESHBHAI", "gender": "M", "batch": "B1", "class": "DIV B"},
    {"sr_no": 14, "roll_no": "246240316130", "name": "PATHAK DIVYA KALPESHKUMAR", "gender": "M", "batch": "B1", "class": "DIV B"},
    {"sr_no": 15, "roll_no": "246240316133", "name": "PRAJAPATI BHAVY RAJENDRAKUMAR", "gender": "M", "batch": "B1", "class": "DIV B"},
    {"sr_no": 16, "roll_no": "246240316134", "name": "PRAJAPATI DEVAM LALITKUMAR", "gender": "M", "batch": "B1", "class": "DIV B"},
    {"sr_no": 17, "roll_no": "246240316136", "name": "PRAJAPATI HANI MANISHBHAI", "gender": "F", "batch": "B1", "class": "DIV B"},
    {"sr_no": 18, "roll_no": "246240316137", "name": "PRAJAPATI HELI RAJESHBHAI", "gender": "F", "batch": "B1", "class": "DIV B"},
    {"sr_no": 19, "roll_no": "246240316139", "name": "PRAJAPATI JANHAVI VIJAYKUMAR", "gender": "F", "batch": "B1", "class": "DIV B"},
    {"sr_no": 20, "roll_no": "246240316141", "name": "PRAJAPATI MILAPKUMAR ATULKUMAR", "gender": "M", "batch": "B1", "class": "DIV B"},

    {"sr_no": 1, "roll_no": "246240316142", "name": "PRAJAPATI NIRMAL BHARATBHAI", "gender": "M", "batch": "B2", "class": "DIV B"},
    {"sr_no": 2, "roll_no": "246240316143", "name": "PRAJAPATI OM RAMESHBHAI", "gender": "M", "batch": "B2", "class": "DIV B"},
    {"sr_no": 3, "roll_no": "246240316145", "name": "PRAJAPATI PAVAN MAHESHKUMAR", "gender": "M", "batch": "B2", "class": "DIV B"},
    {"sr_no": 4, "roll_no": "246240316147", "name": "PRAJAPATI RUTVIBEN PIYUSHBHAI", "gender": "F", "batch": "B2", "class": "DIV B"},
    {"sr_no": 5, "roll_no": "246240316149", "name": "PRAJAPATI YASH SHANKARBHAI", "gender": "M", "batch": "B2", "class": "DIV B"},
    {"sr_no": 6, "roll_no": "246240316151", "name": "RABARI BRIJESHBHAI MOTIBHAI", "gender": "M", "batch": "B2", "class": "DIV B"},
    {"sr_no": 7, "roll_no": "246240316152", "name": "RABARI SIDHDHRAJ JIVANBHAI", "gender": "M", "batch": "B2", "class": "DIV B"},
    {"sr_no": 8, "roll_no": "246240316153", "name": "RAHEVAR KRISHNVARDHANSINH BALBHADRASINH", "gender": "M", "batch": "B2", "class": "DIV B"},
    {"sr_no": 9, "roll_no": "246240316156", "name": "RAJPUT ARYANSINH JITENDRASINH", "gender": "M", "batch": "B2", "class": "DIV B"},
    {"sr_no": 10, "roll_no": "246240316157", "name": "RAMI SAKSHI HITESHKUMAR", "gender": "F", "batch": "B2", "class": "DIV B"},
    {"sr_no": 11, "roll_no": "246240316159", "name": "RATHOD DEVENDRASINH SURESHSINH", "gender": "M", "batch": "B2", "class": "DIV B"},
    {"sr_no": 12, "roll_no": "246240316161", "name": "RATHOD RUTVIKKUMAR CHETANKUMAR", "gender": "M", "batch": "B2", "class": "DIV B"},
    {"sr_no": 13, "roll_no": "246240316164", "name": "RAVAL DAKSH JIGNESHKUMAR", "gender": "M", "batch": "B2", "class": "DIV B"},
    {"sr_no": 14, "roll_no": "246240316165", "name": "RAVAL HET HIRENKUMAR", "gender": "M", "batch": "B2", "class": "DIV B"},
    {"sr_no": 15, "roll_no": "246240316166", "name": "RAVAL UMANG AMRUTBHAI", "gender": "M", "batch": "B2", "class": "DIV B"},
    {"sr_no": 16, "roll_no": "246240316167", "name": "SHAH DIYA PRIYESHBHAI", "gender": "F", "batch": "B2", "class": "DIV B"},
    {"sr_no": 17, "roll_no": "246240316168", "name": "SHARMA KUSHAGRA JITENDRABHAI", "gender": "M", "batch": "B2", "class": "DIV B"},
    {"sr_no": 18, "roll_no": "246240316171", "name": "SHURU JAYVIR DOLATDAN", "gender": "M", "batch": "B2", "class": "DIV B"},
    {"sr_no": 19, "roll_no": "246240316172", "name": "SIMBALIYA KRISKUMAR PRAVINBHAI", "gender": "M", "batch": "B2", "class": "DIV B"},
    {"sr_no": 20, "roll_no": "246240316173", "name": "SIPAI FEZANKHAN SIKANDARKHAN", "gender": "M", "batch": "B2", "class": "DIV B"},

    {"sr_no": 1, "roll_no": "246240316174", "name": "SOLANKI HEER PRASHANTKUMAR", "gender": "F", "batch": "B3", "class": "DIV B"},
    {"sr_no": 2, "roll_no": "246240316176", "name": "SOLANKI RIDDHI DILIPBHAI", "gender": "F", "batch": "B3", "class": "DIV B"},
    {"sr_no": 3, "roll_no": "246240316180", "name": "SUTHAR KRUSHI MAYURKUMAR", "gender": "F", "batch": "B3", "class": "DIV B"},
    {"sr_no": 4, "roll_no": "246240316181", "name": "SUTHAR MADHYA JIGNESHKUMAR", "gender": "F", "batch": "B3", "class": "DIV B"},
    {"sr_no": 5, "roll_no": "246240316184", "name": "SUTHAR VAIBHAV ATULBHAI", "gender": "M", "batch": "B3", "class": "DIV B"},
    {"sr_no": 6, "roll_no": "246240316185", "name": "SUVERA JANVIBAHEN VIKRAMBHAI", "gender": "F", "batch": "B3", "class": "DIV B"},
    {"sr_no": 7, "roll_no": "246240316186", "name": "THAKOR SHITALBEN BHARATBHAI", "gender": "F", "batch": "B3", "class": "DIV B"},
    {"sr_no": 8, "roll_no": "246240316188", "name": "UDASI SATYAM SANJAYKUMAR", "gender": "M", "batch": "B3", "class": "DIV B"},
    {"sr_no": 9, "roll_no": "246240316189", "name": "UPADHYAY YASHKUMAR YOGESHKUMAR", "gender": "M", "batch": "B3", "class": "DIV B"},
    {"sr_no": 10, "roll_no": "246240316192", "name": "VANKAR JAIMINIBAHEN MANHARBHAI", "gender": "F", "batch": "B3", "class": "DIV B"},
    {"sr_no": 11, "roll_no": "246240316193", "name": "VANZARA BIPINKUMAR RAJUBHAI", "gender": "M", "batch": "B3", "class": "DIV B"},
    {"sr_no": 12, "roll_no": "236240316078", "name": "PANCHAL SAHIL JITENDRABHAI", "gender": "M", "batch": "B3", "class": "DIV B"},
    {"sr_no": 13, "roll_no": "236240316140", "name": "RADADIYA SAMBHAV HARESHKUMAR", "gender": "M", "batch": "B3", "class": "DIV B"},
    {"sr_no": 14, "roll_no": "236240316144", "name": "RANA MOHIT CHETANBHAI", "gender": "M", "batch": "B3", "class": "DIV B"},
    {"sr_no": 15, "roll_no": "236240316164", "name": "SONI YAGNIK NARENDRABHAI", "gender": "M", "batch": "B3", "class": "DIV B"},
    {"sr_no": 16, "roll_no": "236240316173", "name": "THAKOR GANPATKUMAR RAMESHBHAI", "gender": "M", "batch": "B3", "class": "DIV B"}
  ];

  static Future<void> seedDatabase(BuildContext context) async {
    const String semester = "4";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Seeding 116 students..."),
          ],
        ),
      ),
    );

    int count = 0;
    try {
      for (final studentMap in _sem4Students) {
        final String className = studentMap['class'].toString();
        // Convert "DIV A" to "A"
        final String division = className.replaceAll('DIV', '').trim();
        final String batch = studentMap['batch'].toString().trim();
        
        final student = Student(
          id: '',
          srNumber: studentMap['sr_no'],
          name: studentMap['name'].toString().trim(),
          enrollmentNumber: studentMap['roll_no'].toString().trim(),
          semester: semester,
          division: division,
          batch: batch,
        );

        try {
          await StudentService.addStudent(
            semester,
            division,
            batch,
            student,
          );
          count++;
        } catch (e) {
          // Ignore duplicates so the loop continues
          if (!e.toString().contains('already exists')) {
            rethrow;
          }
        }
      }

      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully seeded $count students!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error seeding: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
