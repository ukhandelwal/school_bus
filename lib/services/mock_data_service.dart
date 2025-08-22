
import '../models/bus_model.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';

class MockDataService {
  static Bus getMockBus() {
    return Bus(
      id: 'bus_101',
      name: 'Jaipur School Bus 101',
      capacity: 40,
      currentRouteId: 'custom_route_1',
    );
  }

  static Route getMockRoute() {
    return Route(
      id: 'custom_route_1',
      name: 'Jaipur Custom Route (from Google Maps)',
      busId: 'bus_101',
      stops: [
        Stop(
          id: 'stop_1',
          name: 'Datansh Solutions Private Limited',
          latitude: 26.8520616,
          longitude: 75.7947785,
          studentCount: 2,
          status: StopStatus.next,
        ),
        Stop(
          id: 'stop_2',
          name: 'WTP Park, Shobhit Park, Malviya Nagar',
          latitude: 26.8529156,
          longitude: 75.8035951,
          studentCount: 4,
          status: StopStatus.current,
        ),
        Stop(
          id: 'stop_3',
          name: 'Airport Sanganer Sub Post Office (Govind Vihar)',
          latitude: 26.8416215,
          longitude: 75.8014028,
          studentCount: 1,
          status: StopStatus.upcoming,
        ),
        Stop(
          id: 'stop_4',
          name: 'Ajmeri Gate',
          latitude: 26.9179079,
          longitude: 75.8169087,
          studentCount: 2,
          status: StopStatus.upcoming,
        ),
        Stop(
          id: 'stop_5',
          name: 'Patrika Gate',
          latitude: 26.9238937,
          longitude: 75.8316064,
          studentCount: 1,
          status: StopStatus.upcoming,
        ),
        Stop(
          id: 'stop_6',
          name: 'Transport Nagar, Jaipur',
          latitude: 26.9091785,
          longitude: 75.8456936,
          studentCount: 5,
          status: StopStatus.upcoming,
        ),
        Stop(
          id: 'stop_7',
          name: 'Vinayak Enclave',
          latitude: 26.8097546,
          longitude: 75.8720915,
          studentCount: 4,
          status: StopStatus.upcoming,
        ),
        Stop(
          id: 'stop_8',
          name: 'Pratap Nagar, Jaipur',
          latitude: 26.8036533,
          longitude: 75.8084579,
          studentCount: 3,
          status: StopStatus.upcoming,
        ),
        Stop(
          id: 'stop_9',
          name: 'Badi Chaupar, Jaipur',
          latitude: 26.8282742,
          longitude: 75.8056178,
          studentCount: 2,
          status: StopStatus.upcoming,
        ),
      ],
    );
  }

  static List<Stop> getMockStops() {
    return getMockRoute().stops;
  }
}
