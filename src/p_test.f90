program test_xrotor
    use, intrinsic :: iso_c_binding, only : c_int, c_bool, c_float
    use api, only : init, set_case, operate, show, get_number_of_stations, get_station_conditions, set_use_compr_corr, &
            save_prop, load_prop
    real :: rho, vso, rmu, alt, vel, adv, r_hub, r_tip, r_wake, rake
    integer, parameter :: n_geom = 6, n_polars = 1, n_polar_points(n_polars) = (/105/)
    real :: geomdata(4, n_geom), xi_polars(n_polars), polardata(sum(n_polar_points), 4)
    logical(c_bool) :: free, duct, wind, use_compr_corr
    real, allocatable :: xi(:), Re(:), M(:)
    real :: res
    integer :: n_blds

    rho = 1.225
    vso = 340.
    rmu = 1.789e-5
    alt = 1.
    vel = 27.
    adv = .15

    r_hub = .06
    r_tip = .83
    r_wake = 0.
    rake = 0.

    n_blds = 2

    geomdata = reshape((/& !
    !r/R  c/R   beta  ubody
    0.15, 0.15, 50.0, 0.00, &
    0.30, 0.16, 30.7, 0.00, &
    0.45, 0.17, 21.6, 0.00, &
    0.60, 0.16, 16.5, 0.00, &
    0.75, 0.13, 13.4, 0.00, &
    0.90, 0.09, 11.3, 0.00/), (/4, n_geom/))

    xi_polars = 0.
    ! NACA 6412 at Re = 500,000 and M = 0.0
    polardata = reshape((/&
    ! apha [deg]
    -9.5000, -9.2500, -9.0000, -8.7500, -8.5000, -8.2500, -8.0000, &
    -7.7500, -7.5000, -7.2500, -7.0000, -6.7500, -6.5000, -6.0000, &
    -5.7500, -5.5000, -5.2500, -5.0000, -4.7500, -4.5000, -4.2500, &
    -4.0000, -3.7500, -3.5000, -3.2500, -3.0000, -2.7500, -2.5000, &
    -2.2500, -2.0000, -1.7500, -1.5000, -1.2500, -1.0000, -0.7500, &
    -0.5000, -0.2500,  0.0000,  0.2500,  0.5000,  0.7500,  1.0000, &
     1.2500,  1.5000,  1.7500,  2.0000,  2.2500,  2.5000,  2.7500, &
     3.0000,  3.2500,  3.5000,  3.7500,  4.0000,  4.2500,  4.5000, &
     4.7500,  5.0000,  5.2500,  5.5000,  5.7500,  6.0000,  6.2500, &
     6.5000,  6.7500,  7.0000,  7.2500,  7.5000,  7.7500,  8.0000, &
     8.2500,  8.5000,  8.7500,  9.0000,  9.2500,  9.5000,  9.7500, &
    10.0000, 10.2500, 10.5000, 10.7500, 11.0000, 11.2500, 11.5000, &
    11.7500, 12.0000, 12.2500, 12.5000, 12.7500, 13.0000, 13.2500, &
    13.5000, 13.7500, 14.0000, 14.2500, 14.5000, 14.7500, 15.0000, &
    15.2500, 15.5000, 15.7500, 16.0000, 16.2500, 16.5000, 16.7500, &
    ! cl [-]
    -0.1344, -0.2938, -0.2807, -0.2627, -0.2407, -0.2191, -0.1937, &
    -0.1673, -0.1435, -0.1184, -0.0929, -0.0682, -0.0419,  0.0114, &
     0.0372,  0.0643,  0.0908,  0.1179,  0.1441,  0.1714,  0.1976, &
     0.2254,  0.2513,  0.2790,  0.3050,  0.3323,  0.3586,  0.3853, &
     0.4119,  0.4382,  0.4645,  0.4907,  0.5169,  0.5429,  0.5688, &
     0.5946,  0.6201,  0.6458,  0.6712,  0.6963,  0.7212,  0.7419, &
     0.8011,  0.8268,  0.8523,  0.8782,  0.9038,  0.9297,  0.9556, &
     0.9810,  1.0072,  1.0328,  1.0584,  1.0843,  1.1098,  1.1353, &
     1.1609,  1.1861,  1.2116,  1.2367,  1.2611,  1.2856,  1.3093, &
     1.3320,  1.3544,  1.3764,  1.3985,  1.4203,  1.4404,  1.4601, &
     1.4785,  1.4960,  1.5139,  1.5288,  1.5427,  1.5530,  1.5615, &
     1.5684,  1.5732,  1.5761,  1.5778,  1.5792,  1.5797,  1.5818, &
     1.5841,  1.5861,  1.5874,  1.5904,  1.5928,  1.5928,  1.5952, &
     1.5959,  1.5928,  1.5954,  1.5936,  1.5871,  1.5890,  1.5882, &
     1.5833,  1.5733,  1.5732,  1.5708,  1.5677,  1.5633,  1.5568, &
    ! cd [-]
     0.0894,  0.0289,  0.0245,  0.0224,  0.0201,  0.0192,  0.0186, &
     0.0178,  0.0170,  0.0162,  0.0151,  0.0145,  0.0140,  0.0132, &
     0.0125,  0.0122,  0.0119,  0.0114,  0.0112,  0.0109,  0.0106, &
     0.0105,  0.0102,  0.0101,  0.0098,  0.0097,  0.0096,  0.0095, &
     0.0094,  0.0093,  0.0092,  0.0091,  0.0091,  0.0091,  0.0091, &
     0.0091,  0.0091,  0.0091,  0.0091,  0.0091,  0.0090,  0.0086, &
     0.0080,  0.0081,  0.0083,  0.0085,  0.0086,  0.0088,  0.0089, &
     0.0091,  0.0093,  0.0094,  0.0096,  0.0098,  0.0100,  0.0102, &
     0.0103,  0.0105,  0.0107,  0.0109,  0.0111,  0.0113,  0.0115, &
     0.0117,  0.0119,  0.0121,  0.0123,  0.0126,  0.0128,  0.0131, &
     0.0134,  0.0138,  0.0142,  0.0147,  0.0153,  0.0161,  0.0171, &
     0.0182,  0.0196,  0.0210,  0.0227,  0.0244,  0.0263,  0.0281, &
     0.0300,  0.0320,  0.0341,  0.0362,  0.0383,  0.0408,  0.0432, &
     0.0458,  0.0489,  0.0515,  0.0546,  0.0583,  0.0611,  0.0643, &
     0.0681,  0.0726,  0.0758,  0.0794,  0.0831,  0.0870,  0.0912, &
    ! cm [-]
    -0.0883, -0.1484, -0.1502, -0.1500, -0.1503, -0.1496, -0.1494, &
    -0.1494, -0.1489, -0.1484, -0.1482, -0.1477, -0.1474, -0.1467, &
    -0.1464, -0.1461, -0.1457, -0.1455, -0.1450, -0.1448, -0.1444, &
    -0.1441, -0.1437, -0.1435, -0.1430, -0.1427, -0.1423, -0.1420, &
    -0.1416, -0.1411, -0.1407, -0.1403, -0.1398, -0.1393, -0.1389, &
    -0.1384, -0.1378, -0.1373, -0.1368, -0.1362, -0.1356, -0.1343, &
    -0.1414, -0.1409, -0.1404, -0.1399, -0.1395, -0.1391, -0.1387, &
    -0.1382, -0.1379, -0.1375, -0.1371, -0.1367, -0.1363, -0.1359, &
    -0.1355, -0.1351, -0.1347, -0.1342, -0.1337, -0.1331, -0.1324, &
    -0.1315, -0.1305, -0.1295, -0.1286, -0.1276, -0.1262, -0.1248, &
    -0.1232, -0.1215, -0.1199, -0.1178, -0.1157, -0.1131, -0.1104, &
    -0.1076, -0.1046, -0.1016, -0.0986, -0.0957, -0.0930, -0.0906, &
    -0.0884, -0.0864, -0.0845, -0.0829, -0.0814, -0.0800, -0.0788, &
    -0.0778, -0.0767, -0.0760, -0.0753, -0.0746, -0.0742, -0.0739, &
    -0.0737, -0.0735, -0.0735, -0.0735, -0.0736, -0.0739, -0.0743/), (/105, 4/))

    free = .true.
    duct = .false.
    wind = .false.

    use_compr_corr = .false.

    call init()
!    call set_case(&
!        rho, vso, rmu, alt, vel, adv, &
!        r_hub, r_tip, r_wake, rake, &
!        n_blds, &
!        n_geom, geomdata, &
!        n_polars, n_polar_points, xi_polars, polardata, &
!        free, duct, wind)
!    call set_use_compr_corr(use_compr_corr)
!    res = operate(4, 2000.)
!    call show()
!
!    call save_prop()

    call init()
    call load_prop('output.json')
    call set_use_compr_corr(use_compr_corr)
    res = operate(4, 2000.)
    call show()

    n_stations = get_number_of_stations()
    allocate(xi(n_stations))
    allocate(Re(n_stations))
    allocate(M(n_stations))
    call get_station_conditions(n_stations, xi, Re, M)
end program test_xrotor