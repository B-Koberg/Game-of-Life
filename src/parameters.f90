module parameters
    use iso_fortran_env, only: int32, real64, real32
    use json_module
    implicit none
    public :: wp
    public :: nx, ny, max_iter, x_min, x_max, y_min, y_max

    integer :: wp = real64

    integer :: ratio_x, ratio_y 
    integer :: base_size 
    integer :: max_iter 
    character(len=1) :: files 
    
    integer :: nx, ny
    real(real64) :: x_min, x_max, y_min, y_max

contains
    subroutine load_parameters(file)
        use iso_fortran_env, only: int32, real64, real32
        use json_module
        character(len=*), intent(in) :: file
        logical :: is_found
        integer :: time(8)
        type(json_file) :: json
        character(len=:), allocatable :: wp_string
        character(len=:), allocatable :: files_string
        real(real64) :: y_half_span64
        real(real32) :: y_half_span32

        call json%initialize()

        call json%load_file(file); if (json%failed()) stop 'Failed to load JSON file'

        json_block: block
            call json%get('wp', wp_string, is_found); if (.not. is_found) exit json_block
            call json%get('ratio_x', ratio_x, is_found); if (.not. is_found) exit json_block
            call json%get('ratio_y', ratio_y, is_found); if (.not. is_found) exit json_block
            call json%get('base_size', base_size, is_found); if (.not. is_found) exit json_block
            call json%get('max_iter', max_iter, is_found); if (.not. is_found) exit json_block
            call json%get('mult_files', files_string, is_found); if (.not. is_found) exit json_block
            call json%get('x_min', x_min, is_found); if (.not. is_found) exit json_block
            call json%get('x_max', x_max, is_found); if (.not. is_found) exit json_block
        end block json_block

        if (allocated(files_string) .and. (len_trim(files_string) == 1)) then
            files = trim(adjustl(files_string))
        else
            print *, 'Invalid mult_files in JSON. Expected a single character m or s.'
            is_found = .false.
        end if

        if (.not. is_found) then
            print *, 'Failed to load required keys from JSON file.'
            call json%destroy()
            return
        end if

        select case (trim(adjustl(wp_string)))
        case ('real64')
            wp = real64
        case ('real32')
            wp = real32
        case default
            is_found = .false.
            print *, 'Invalid wp in JSON. Expected real64 or real32.'
        end select

        if(is_found) then
            nx = ratio_x * base_size
            ny = ratio_y * base_size

            if (wp == real32) then
                y_half_span32 = (real(x_max, real32) - real(x_min, real32)) * &
                    real(ny, real32) / real(nx, real32) / 2.0_real32
                y_min = -real(y_half_span32, real64)
            else
                y_half_span64 = (x_max - x_min) * real(ny, real64) / real(nx, real64) / 2.0_real64
                y_min = -y_half_span64
            end if
            y_max = - y_min

            call date_and_time(values=time)
            write(*,'("(",I2.2,":",I2.2,":",I2.2,") Found Json File and loaded all Parameters")') &
                time(5), time(6), time(7)
        else
            print *, 'Failed to find x or y in JSON file'
        end if

        call json%destroy()
    end subroutine load_parameters
end module parameters
