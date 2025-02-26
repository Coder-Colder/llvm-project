! This test checks lowering of OpenACC declare directive.

! RUN: bbc -fopenacc -emit-fir %s -o - | FileCheck %s

module acc_declare_test
 integer, parameter :: n = 100000
 real, dimension(n) :: data1
 !$acc declare create(data1)
end module

! CHECK-LABEL: fir.global @_QMacc_declare_testEdata1 {acc.declare = #acc.declare<dataClause = acc_create>} : !fir.array<100000xf32>

! CHECK-LABEL: acc.global_ctor @_QMacc_declare_testEdata1_acc_ctor {
! CHECK:         %[[GLOBAL_ADDR:.*]] = fir.address_of(@_QMacc_declare_testEdata1) {acc.declare = #acc.declare<dataClause = acc_create>} : !fir.ref<!fir.array<100000xf32>>
! CHECK:         %[[CREATE:.*]] = acc.create varPtr(%[[GLOBAL_ADDR]] : !fir.ref<!fir.array<100000xf32>>) -> !fir.ref<!fir.array<100000xf32>> {name = "data1", structured = false}
! CHECK:         acc.declare_enter dataOperands(%[[CREATE]] : !fir.ref<!fir.array<100000xf32>>)
! CHECK:         acc.terminator
! CHECK:       }

! CHECK-LABEL: acc.global_dtor @_QMacc_declare_testEdata1_acc_dtor {
! CHECK:         %[[GLOBAL_ADDR:.*]] = fir.address_of(@_QMacc_declare_testEdata1) {acc.declare = #acc.declare<dataClause = acc_create>} : !fir.ref<!fir.array<100000xf32>>
! CHECK:         %[[DEVICEPTR:.*]] = acc.getdeviceptr varPtr(%[[GLOBAL_ADDR]] : !fir.ref<!fir.array<100000xf32>>) -> !fir.ref<!fir.array<100000xf32>> {dataClause = #acc<data_clause acc_create>, name = "data1", structured = false}
! CHECK:         acc.declare_exit dataOperands(%[[DEVICEPTR]] : !fir.ref<!fir.array<100000xf32>>)
! CHECK:         acc.delete accPtr(%[[DEVICEPTR]] : !fir.ref<!fir.array<100000xf32>>) {dataClause = #acc<data_clause acc_create>, name = "data1", structured = false}
! CHECK:         acc.terminator
! CHECK:       }

module acc_declare_copyin_test
 integer, parameter :: n = 100000
 real, dimension(n) :: data1
 !$acc declare copyin(data1)
end module


! CHECK-LABEL: acc.global_ctor @_QMacc_declare_copyin_testEdata1_acc_ctor {
! CHECK:         %[[GLOBAL_ADDR:.*]] = fir.address_of(@_QMacc_declare_copyin_testEdata1) {acc.declare = #acc.declare<dataClause =  acc_copyin>} : !fir.ref<!fir.array<100000xf32>>
! CHECK:         %[[COPYIN:.*]] = acc.copyin varPtr(%[[GLOBAL_ADDR]] : !fir.ref<!fir.array<100000xf32>>) -> !fir.ref<!fir.array<100000xf32>> {name = "data1", structured = false}
! CHECK:         acc.declare_enter dataOperands(%[[COPYIN]] : !fir.ref<!fir.array<100000xf32>>)
! CHECK:         acc.terminator
! CHECK:       }

module acc_declare_device_resident_test
 integer, parameter :: n = 5000
 integer, dimension(n) :: data1
 !$acc declare device_resident(data1)
end module

! CHECK-LABEL: fir.global @_QMacc_declare_device_resident_testEdata1 {acc.declare = #acc.declare<dataClause =  acc_declare_device_resident>} : !fir.array<5000xi32>

! CHECK-LABEL: acc.global_ctor @_QMacc_declare_device_resident_testEdata1_acc_ctor {
! CHECK:         %[[GLOBAL_ADDR:.*]] = fir.address_of(@_QMacc_declare_device_resident_testEdata1) {acc.declare = #acc.declare<dataClause =  acc_declare_device_resident>} : !fir.ref<!fir.array<5000xi32>>
! CHECK:         %[[DEVICERESIDENT:.*]] = acc.declare_device_resident varPtr(%0 : !fir.ref<!fir.array<5000xi32>>) -> !fir.ref<!fir.array<5000xi32>> {name = "data1", structured = false}
! CHECK:         acc.declare_enter dataOperands(%[[DEVICERESIDENT]] : !fir.ref<!fir.array<5000xi32>>)
! CHECK:         acc.terminator
! CHECK:       }

module acc_declare_device_link_test
 integer, parameter :: n = 5000
 integer, dimension(n) :: data1
 !$acc declare link(data1)
end module

! CHECK-LABEL: fir.global @_QMacc_declare_device_link_testEdata1 {acc.declare = #acc.declare<dataClause =  acc_declare_link>} : !fir.array<5000xi32> {

! CHECK-LABEL: acc.global_ctor @_QMacc_declare_device_link_testEdata1_acc_ctor {
! CHECK:         %[[GLOBAL_ADDR:.*]] = fir.address_of(@_QMacc_declare_device_link_testEdata1) {acc.declare = #acc.declare<dataClause =  acc_declare_link>} : !fir.ref<!fir.array<5000xi32>>
! CHECK:         %[[LINK:.*]] = acc.declare_link varPtr(%[[GLOBAL_ADDR]] : !fir.ref<!fir.array<5000xi32>>) -> !fir.ref<!fir.array<5000xi32>> {name = "data1", structured = false}
! CHECK:         acc.declare_enter dataOperands(%[[LINK]] : !fir.ref<!fir.array<5000xi32>>)
! CHECK:         acc.terminator
! CHECK:       }

module acc_declare
  contains

  subroutine acc_declare_copy()
    integer :: a(100), i
    !$acc declare copy(a)

    do i = 1, 100
      a(i) = i
    end do
  end subroutine

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_copy()
! CHECK: %[[ALLOCA:.*]] = fir.alloca !fir.array<100xi32> {acc.declare = #acc.declare<dataClause =  acc_copy>, bindc_name = "a", uniq_name = "_QMacc_declareFacc_declare_copyEa"}
! CHECK: %[[BOUND:.*]] = acc.bounds   lowerbound(%{{.*}} : index) upperbound(%{{.*}} : index) extent(%{{.*}} : index) stride(%c1 : index) startIdx(%c1 : index)
! CHECK: %[[COPYIN:.*]] = acc.copyin varPtr(%[[ALLOCA]] : !fir.ref<!fir.array<100xi32>>) bounds(%[[BOUND]]) -> !fir.ref<!fir.array<100xi32>> {dataClause = #acc<data_clause acc_copy>, name = "a"}
! CHECK: acc.declare_enter dataOperands(%[[COPYIN]] : !fir.ref<!fir.array<100xi32>>)

! CHECK: %{{.*}}:2 = fir.do_loop %{{.*}} = %{{.*}} to %{{.*}} step %{{.*}} iter_args(%{{.*}} = %{{.*}}) -> (index, i32) {
! CHECK: }

! CHECK: acc.declare_exit dataOperands(%[[COPYIN]] : !fir.ref<!fir.array<100xi32>>)
! CHECK: acc.copyout accPtr(%[[COPYIN]] : !fir.ref<!fir.array<100xi32>>) bounds(%[[BOUND]]) to varPtr(%[[ALLOCA]] : !fir.ref<!fir.array<100xi32>>) {dataClause = #acc<data_clause acc_copy>, name = "a"}

! CHECK: return

  subroutine acc_declare_create()
    integer :: a(100), i
    !$acc declare create(a)

    do i = 1, 100
      a(i) = i
    end do
  end subroutine

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_create() {
    
! CHECK: %[[ALLOCA:.*]] = fir.alloca !fir.array<100xi32> {acc.declare = #acc.declare<dataClause =  acc_create>, bindc_name = "a", uniq_name = "_QMacc_declareFacc_declare_createEa"}
! CHECK: %[[BOUND:.*]] = acc.bounds   lowerbound(%{{.*}} : index) upperbound(%{{.*}} : index) extent(%{{.*}} : index) stride(%c1 : index) startIdx(%c1 : index)
! CHECK: %[[CREATE:.*]] = acc.create varPtr(%[[ALLOCA]] : !fir.ref<!fir.array<100xi32>>) bounds(%[[BOUND]]) -> !fir.ref<!fir.array<100xi32>> {name = "a"}
! CHECK: acc.declare_enter dataOperands(%[[CREATE]] : !fir.ref<!fir.array<100xi32>>)

! CHECK: %{{.*}}:2 = fir.do_loop %{{.*}} = %{{.*}} to %{{.*}} step %{{.*}} iter_args(%{{.*}} = %{{.*}}) -> (index, i32) {
! CHECK: }

! CHECK: acc.declare_exit dataOperands(%[[CREATE]] : !fir.ref<!fir.array<100xi32>>)
! CHECK: acc.delete accPtr(%[[CREATE]] : !fir.ref<!fir.array<100xi32>>) bounds(%[[BOUND]]) {dataClause = #acc<data_clause acc_create>, name = "a"}
! CHECK: return

  subroutine acc_declare_present(a)
    integer :: a(100), i
    !$acc declare present(a)

    do i = 1, 100
      a(i) = i
    end do
  end subroutine

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_present(
! CHECK-SAME: %[[ARG0:.*]]: !fir.ref<!fir.array<100xi32>> {fir.bindc_name = "a"})
! CHECK: %[[BOUND:.*]] = acc.bounds lowerbound(%{{.*}} : index) upperbound(%{{.*}} : index) extent(%{{.*}} : index) stride(%{{.*}} : index) startIdx(%c1 : index)
! CHECK: %[[PRESENT:.*]] = acc.present varPtr(%[[ARG0]] : !fir.ref<!fir.array<100xi32>>) bounds(%[[BOUND]]) -> !fir.ref<!fir.array<100xi32>> {name = "a"}
! CHECK: acc.declare_enter dataOperands(%[[PRESENT]] : !fir.ref<!fir.array<100xi32>>)
! CHECK: %{{.*}}:2 = fir.do_loop %{{.*}} = %{{.*}} to %{{.*}} step %{{.*}} iter_args(%arg{{.*}} = %{{.*}}) -> (index, i32)
! CHECK-NOT: acc.declare_exit

  subroutine acc_declare_copyin()
    integer :: a(100), b(10), i
    !$acc declare copyin(a) copyin(readonly: b)

    do i = 1, 100
      a(i) = i
    end do
  end subroutine

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_copyin()
! CHECK: %[[A:.*]] = fir.alloca !fir.array<100xi32> {acc.declare = #acc.declare<dataClause =  acc_copyin>, bindc_name = "a", uniq_name = "_QMacc_declareFacc_declare_copyinEa"}
! CHECK: %[[B:.*]] = fir.alloca !fir.array<10xi32> {acc.declare = #acc.declare<dataClause =  acc_copyin_readonly>, bindc_name = "b", uniq_name = "_QMacc_declareFacc_declare_copyinEb"}
! CHECK: %[[BOUND:.*]] = acc.bounds lowerbound(%{{.*}} : index) upperbound(%{{.*}} : index) extent(%{{.*}} : index) stride(%{{.*}} : index) startIdx(%{{.*}} : index)
! CHECK: %[[COPYIN_A:.*]] = acc.copyin varPtr(%[[A]] : !fir.ref<!fir.array<100xi32>>) bounds(%[[BOUND]]) -> !fir.ref<!fir.array<100xi32>> {name = "a"}
! CHECK: %[[BOUND:.*]] = acc.bounds lowerbound(%{{.*}} : index) upperbound(%{{.*}} : index) extent(%{{.*}} : index) stride(%{{.*}} : index) startIdx(%{{.*}} : index)
! CHECK: %[[COPYIN_B:.*]] = acc.copyin varPtr(%[[B]] : !fir.ref<!fir.array<10xi32>>) bounds(%[[BOUND]]) -> !fir.ref<!fir.array<10xi32>> {dataClause = #acc<data_clause acc_copyin_readonly>, name = "b"}
! CHECK: acc.declare_enter dataOperands(%[[COPYIN_A]], %[[COPYIN_B]] : !fir.ref<!fir.array<100xi32>>, !fir.ref<!fir.array<10xi32>>)
! CHECK: %{{.*}}:2 = fir.do_loop %{{.*}} = %{{.*}} to %{{.*}} step %{{.*}} iter_args(%arg{{.*}} = %{{.*}}) -> (index, i32)
! CHECK-NOT: acc.declare_exit

  subroutine acc_declare_copyout()
    integer :: a(100), i
    !$acc declare copyout(a)

    do i = 1, 100
      a(i) = i
    end do
  end subroutine

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_copyout()
! CHECK: %[[A:.*]] = fir.alloca !fir.array<100xi32> {acc.declare = #acc.declare<dataClause =  acc_copyout>, bindc_name = "a", uniq_name = "_QMacc_declareFacc_declare_copyoutEa"}
! CHECK: %[[CREATE:.*]] = acc.create varPtr(%[[A]] : !fir.ref<!fir.array<100xi32>>) bounds(%{{.*}}) -> !fir.ref<!fir.array<100xi32>> {dataClause = #acc<data_clause acc_copyout>, name = "a"}
! CHECK: acc.declare_enter dataOperands(%[[CREATE]] : !fir.ref<!fir.array<100xi32>>)
! CHECK: %{{.*}}:2 = fir.do_loop %{{.*}} = %{{.*}} to %{{.*}} step %{{.*}} iter_args(%arg{{.*}} = %{{.*}}) -> (index, i32)
! CHECK: acc.declare_exit dataOperands(%[[CREATE]] : !fir.ref<!fir.array<100xi32>>)
! CHECK: acc.copyout accPtr(%[[CREATE]] : !fir.ref<!fir.array<100xi32>>) bounds(%{{.*}}) to varPtr(%[[A]] : !fir.ref<!fir.array<100xi32>>) {name = "a"}
! CHECK: return

  subroutine acc_declare_deviceptr(a)
    integer :: a(100), i
    !$acc declare deviceptr(a)

    do i = 1, 100
      a(i) = i
    end do
  end subroutine

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_deviceptr(
! CHECK-SAME: %[[ARG0:.*]]: !fir.ref<!fir.array<100xi32>> {fir.bindc_name = "a"}) {
! CHECK: %[[DEVICEPTR:.*]] = acc.deviceptr varPtr(%[[ARG0]] : !fir.ref<!fir.array<100xi32>>) bounds(%{{.*}}) -> !fir.ref<!fir.array<100xi32>> {name = "a"}
! CHECK: acc.declare_enter dataOperands(%[[DEVICEPTR]] : !fir.ref<!fir.array<100xi32>>)
! CHECK: %{{.*}}:2 = fir.do_loop %{{.*}} = %{{.*}} to %{{.*}} step %{{.*}} iter_args(%arg{{.*}} = %{{.*}}) -> (index, i32)
! CHECK-NOT: acc.declare_exit

end module
