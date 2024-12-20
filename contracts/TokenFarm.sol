// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./DAppToken.sol";
import "./LPToken.sol";



/**
 * @title Proportional Token Farm
 * @notice Una granja de staking donde las recompensas se distribuyen proporcionalmente al total stakeado.
 */
contract TokenFarm {
    string public name = "Proportional Token Farm";
    address public owner;
    DAppToken public dappToken;
    LPToken public lpToken;

    uint256 public constant REWARD_PER_BLOCK = 1e18; // Recompensa por bloque (total para todos los usuarios)
    uint256 public totalStakingBalance; // Total de tokens en staking

    address[] public stakers;
    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public checkpoints;
    mapping(address => uint256) public pendingRewards;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    // Eventos
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsDistributed(address indexed user, uint256 amount);

    // Constructor
    constructor(DAppToken _dappToken, LPToken _lpToken) {
        dappToken = _dappToken; // Asignar contrato de DappToken
        lpToken = _lpToken;     // Asignar contrato de LPToken
        owner = msg.sender;     // Configurar al owner como el creador del contrato
    }

    /**
     * @notice Deposita tokens LP para staking.
     * @param _amount Cantidad de tokens LP a depositar.
     */
    function deposit(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");

        // Transferir tokens LP del usuario al contrato de staking
        lpToken.transferFrom(msg.sender, address(this), _amount);

        // Actualizar el balance de staking
        stakingBalance[msg.sender] += _amount;
        totalStakingBalance += _amount;

        // Si el usuario no ha staked antes, agregarlo al array de stakers
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
            hasStaked[msg.sender] = true;
        }

        // Actualizar el estado de isStaking
        isStaking[msg.sender] = true;

        // Llamar a distributeRewards para actualizar las recompensas pendientes
        distributeRewards(msg.sender);

        // Emitir un evento de depósito
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice Retira todos los tokens LP en staking.
     */
    function withdraw() external {
        require(isStaking[msg.sender], "You are not staking");

        uint256 balance = stakingBalance[msg.sender];
        require(balance > 0, "No staked tokens to withdraw");

        // Calcular y distribuir las recompensas pendientes antes de retirar
        distributeRewards(msg.sender);

        // Actualizar el balance de staking
        stakingBalance[msg.sender] = 0;
        totalStakingBalance -= balance;

        // Marcar al usuario como no staking
        isStaking[msg.sender] = false;

        // Transferir los tokens LP de vuelta al usuario
        lpToken.transfer(msg.sender, balance);

        // Emitir un evento de retiro
        emit Withdraw(msg.sender, balance);
    }

    /**
     * @notice Reclama recompensas pendientes.
     */
    function claimRewards() external {
        uint256 pendingAmount = pendingRewards[msg.sender];
        require(pendingAmount > 0, "No rewards to claim");

        // Restablecer las recompensas pendientes a 0
        pendingRewards[msg.sender] = 0;

        // Llamar a la función mint para transferir las recompensas al usuario
        dappToken.mint(msg.sender, pendingAmount);

        // Emitir un evento de reclamo de recompensas
        emit RewardsClaimed(msg.sender, pendingAmount);
    }

    /**
     * @notice Distribuye recompensas a todos los usuarios en staking.
     */
    function distributeRewardsAll() external {
        require(msg.sender == owner, "Only owner can distribute rewards");

        // Iterar sobre todos los usuarios en staking
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            if (isStaking[staker]) {
                distributeRewards(staker);
            }
        }

        // Emitir un evento indicando que las recompensas fueron distribuidas
        emit RewardsDistributed(msg.sender, REWARD_PER_BLOCK);
    }

    /**
     * @notice Calcula y distribuye las recompensas proporcionalmente al staking total.
     */
    function distributeRewards(address beneficiary) private {
        uint256 lastCheckpoint = checkpoints[beneficiary];
        if (lastCheckpoint == 0) {
            lastCheckpoint = block.number;  // Inicializar checkpoint si no existe
        }

        // Verificar si han pasado bloques desde el último checkpoint
        if (block.number > lastCheckpoint && totalStakingBalance > 0) {
            uint256 blocksPassed = block.number - lastCheckpoint;
            uint256 userShare = stakingBalance[beneficiary] * 1e18 / totalStakingBalance;
            uint256 reward = (REWARD_PER_BLOCK * blocksPassed * userShare) / 1e18;

            // Acumular las recompensas en pendingRewards
            pendingRewards[beneficiary] += reward;

            // Actualizar el checkpoint del usuario
            checkpoints[beneficiary] = block.number;
        }
    }
}
