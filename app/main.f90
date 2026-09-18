program GOL
    use hdf5
    use omp_lib
    use parameters
    use gol_utils, only: initialize_board, step_generation, swap_boards
    use hdf5_utils, only: hdf5_init_run, save_frame, hdf5_close_run
    implicit none

    integer :: frame

    !Für HDF5 speichern
    integer(HID_T) :: file_id, dset_id, filespace_id, memspace_id

    integer, allocatable :: board_current(:,:), board_next(:,:)

    real :: perc
    integer :: saved_frame

    !Simulationsparameter aus JSON laden
    call load_parameters('params.json')
    call print_time("Prozessparameter aus params.json geladen.")

    allocate(board_current(nx, ny))
    allocate(board_next(nx, ny))
    call initialize_board(board_current)
    board_next = 0

    !Initialisiere HDF5 Datei und Dataset auf Rank 0; Init board speichern
    call hdf5_init_run( file_id, dset_id, filespace_id, memspace_id)

   
    saved_frame = 1
    call save_frame(board_current, saved_frame, dset_id, filespace_id, memspace_id)  ! initialen Frame 1 speichern

    call print_time("Berechnung gestartet...")


    !Main Loop: Boards exchangen, Step generieren, speichern.
    perc = 0.0
    do frame = 2, frames + 1
        call step_generation(board_current, board_next)
        call swap_boards(board_current, board_next)

        if (mod(frame, delta_frames) == 0) then
            saved_frame = saved_frame + 1
            call save_frame(board_current, saved_frame, dset_id, filespace_id, memspace_id)
        end if
        
        perc = real(frame) / real(frames+1) * 100.0
        if (mod(int(perc), 10) == 0) then
            call print_time("Fortschritt: "//trim(itoc(int(perc)))//"%")
        end if
    end do

    call print_time("Game-of-Life Frame-Berechnung abgeschlossen")

    call hdf5_close_run(file_id, dset_id, filespace_id, memspace_id)

    call print_time("Game-of-Life Simulation abgeschlossen. Beende...")

contains
    subroutine print_time(message)
        character(len=*), intent(in) :: message
        integer :: time(8)

        call date_and_time(values=time)
        write(*,'("(",I2.2,":",I2.2,":",I2.2,") ",A)') &
            time(5), time(6), time(7), message
    end subroutine print_time

    character(len=3) function itoc(value) result(str)
        integer, intent(in) :: value
        write(str, '(I0)') value
    end function itoc
end program GOL