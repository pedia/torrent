import 'package:gurgdl/stats.dart';
import 'package:test/test.dart';

void main() {
  test('stats', () {
    final st = Stats();
    st.apply(StatsItem(0, 1, 0, 0, 0, 0), when: DateTime(2022, 1, 1, 0, 0, 0));
    expect(st.speedOfUpload.toString(), '0 B/s');
    
    st.apply(StatsItem(0, 1, 0, 0, 0, 0), when: DateTime(2022, 1, 1, 0, 0, 1));
    expect(st.speedOfUpload.toString(), '1 B/s');
    
    st.apply(StatsItem(0, 5, 0, 0, 0, 0), when: DateTime(2022, 1, 1, 0, 0, 2));
    expect(st.speedOfUpload.toString(), '3 B/s');

    st.apply(StatsItem(0, 3078, 0, 0, 0, 0), when: DateTime(2022, 1, 1, 0, 0, 3));
    expect(st.speedOfUpload.toString(), '1 KB/s');
    
    st.apply(StatsItem(0, 1023993, 0, 0, 0, 0), when: DateTime(2022, 1, 1, 0, 0, 4));
    expect(st.speedOfUpload.toString(), '251 KB/s');
  });
}
