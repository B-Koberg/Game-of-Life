program GOL
    use hdf5
    use omp_lib
    use parameters
    use gol_utils, only: initialize_board, step_generation, swap_boards
    use hdf5_utils, only: hdf5_init_run, save_frame, hdf5_close_run
    implicit none

    integer :: frame

    !Brauche File-ID, Dataset-ID, Filespace-ID (beschreibt größe / format), Memspace-ID (Ram zuordnung)
    integer(HID_T) :: file_id, dset_id, filespace_id, memspace_id

    integer, allocatable :: board_current(:,:), board_next(:,:)

    real :: perc
    integer :: saved


    call load_parameters('params.json')
    call print_time("Prozessparameter aus params.json geladen.")

    allocate(board_current(nx, ny))
    allocate(board_next(nx, ny))
    call initialize_board(board_current)
    board_next = 0


    call hdf5_init_run( file_id, dset_id, filespace_id, memspace_id)

   
    saved = 1                                                                                   ! für das richtige speichern der frames mit delta frames
    call save_frame(board_current, saved, dset_id, filespace_id, memspace_id)  ! initialen Frame 1 speichern

    call print_time("Berechnung gestartet...")

    perc = 0.0
    do frame = 2, frames + 1
        call step_generation(board_current, board_next)
        call swap_boards(board_current, board_next)

        if (mod(frame, delta_frames) == 0) then
            saved = saved + 1
            call save_frame(board_current, saved, dset_id, filespace_id, memspace_id)
        end if
        
        perc = real(frame) / real(frames+1) * 100.0
        if (mod(int(perc), 10) == 0) then
            call print_time("Fortschritt: "//trim(itoa(int(perc)))//"%")
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

    function itoa(i) result(str)
        integer, intent(in) :: i
        character(len=16) :: str
        write(str, '(I0)') i
    end function itoa
end program GOL