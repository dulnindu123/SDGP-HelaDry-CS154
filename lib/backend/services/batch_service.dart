import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class BatchService {
  final Firebase _auth = FirebaseAuth.instance;
  final FirebaseDayabase _db = FirebaseDatabase.instance;

  Stream<<String,dynamic>?> listenToActiveBatch(){
    final user= _auth.currentUser;
    if(user==null) return Stream.value(null);

    final ref= _db.ref('users/${user.uid}/sessions');

    return ref.onValue.map((event){
      final data= event.snapshot.value;
      if(data==null || data is ! Map) retrun null;

      final sessions=Map<String, dynamic>.from(data);

      for(final entry in sessions.entries){
        final session=Map<String, dynamic>.from(entry.value);

        if(session['status']=='active'){
          return{
            'sessionId':entry.key,
            'crop':session['crop']??0.0,
            'startTime':session['stratTime']??0,
            'deviceId':session['deviceId']??'device-001',
            'status':session['status'],
          };
        }
      }
      return null;
    }

    );
  }
}
