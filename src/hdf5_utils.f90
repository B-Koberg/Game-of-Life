module hdf5_utils
  use hdf5
  use parameters
  implicit none
  public :: hdf5_init_run, hdf5_write_frame, hdf5_close_run, save_frame
contains

  subroutine hdf5_init_run(file_id, dset_id, filespace_id, memspace_id)
    integer(HID_T), intent(out) :: file_id, dset_id, filespace_id, memspace_id
    integer(HSIZE_T), dimension(3) :: dims, memdims
    integer :: h5err

    dims(1) = 1 + ceiling(real(frames)/real(delta_frames))
    dims(2) = nx
    dims(3) = ny

    memdims(1) = 1
    memdims(2) = nx
    memdims(3) = ny

    call h5open_f(h5err)
    if (h5err /= 0) stop "h5open_f failed"

    ! Erstelle Datei mit file_id und filename fname
    call h5fcreate_f(trim(output_file), H5F_ACC_TRUNC_F, file_id, h5err)
    ! Erstelle Dataspace in der Datei (alle Frames der Simulation)
    call h5screate_simple_f(3, dims, filespace_id, h5err)
    ! Erstelle Dataset "frames" in der Datei, das den Dataspace nutzt
    call h5dcreate_f(file_id, "frames", H5T_NATIVE_INTEGER, filespace_id, dset_id, h5err)
    ! Erstelle Dataspace im Speicher (ein einzelner Frame)
    call h5screate_simple_f(3, memdims, memspace_id, h5err)
  end subroutine hdf5_init_run


  subroutine hdf5_write_frame(dset_id, filespace_id, memspace_id, frame_index, board)
    integer(HID_T), intent(in) :: dset_id, filespace_id, memspace_id
    integer, intent(in) :: frame_index        
    integer, intent(in) :: board(nx, ny)
    integer(HSIZE_T), dimension(3) :: start, count, memdims
    integer :: h5err

    start(1) = frame_index
    start(2) = 0
    start(3) = 0

    count(1) = 1
    count(2) = nx
    count(3) = ny

    memdims(1) = 1
    memdims(2) = nx
    memdims(3) = ny

    ! Selectiere eine Hyperslab (ein Frame) in der Datei-Dataspace, start gibt position, count dimensions
    call h5sselect_hyperslab_f(filespace_id, H5S_SELECT_SET_F, start, count, h5err)
    ! Schreibe board aus dem Speicher (memspace) in die selektierte Hyperslab
    call h5dwrite_f(dset_id, H5T_NATIVE_INTEGER, board, memdims, h5err, &
                    file_space_id = filespace_id, mem_space_id = memspace_id)

  end subroutine hdf5_write_frame


  subroutine save_frame(board, frame, dset_id, filespace_id, memspace_id)
    integer, intent(in) :: frame
    integer, intent(in) :: board(nx, ny)
    integer(HID_T), intent(in) :: dset_id, filespace_id, memspace_id

    call hdf5_write_frame(dset_id, filespace_id, memspace_id, frame - 1, board)
  end subroutine save_frame


  subroutine hdf5_close_run(file_id, dset_id, filespace_id, memspace_id)
    integer(HID_T), intent(in) :: file_id, dset_id, filespace_id, memspace_id
    integer :: h5err

    call h5dclose_f(dset_id, h5err)
    call h5sclose_f(filespace_id, h5err)
    call h5sclose_f(memspace_id, h5err)
    call h5fclose_f(file_id, h5err)
    call h5close_f(h5err)
  end subroutine hdf5_close_run

end module hdf5_utils
